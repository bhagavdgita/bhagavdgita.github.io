//
//  ContentView.swift
//  Gita
//
//  Contains main source code for App
//
//  Created by SHASHI JAKKIPALLY on 4/13/22.
//

import SwiftUI
import WebKit
import Auth0
import Foundation
import CryptoKit
import MLKitTranslate
import SwiftyJSON

// UIViewRepresentables and styles
struct WebView: UIViewRepresentable {

    var url: URL

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        
        let request = URLRequest(url: url)
        webView.load(request)
        webView.scrollView.isScrollEnabled = false
    }
}




// https://roddy.io/2020/09/07/add-search-bar-to-swiftui-picker/
struct SearchBar: UIViewRepresentable {

    @Binding var text: String
    var placeholder: String

    func makeUIView(context: UIViewRepresentableContext<SearchBar>) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator

        searchBar.placeholder = placeholder
        searchBar.autocapitalizationType = .none
        searchBar.searchBarStyle = .minimal
        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: UIViewRepresentableContext<SearchBar>) {
        uiView.text = text
    }

    func makeCoordinator() -> SearchBar.Coordinator {
        return Coordinator(text: $text)
    }

    class Coordinator: NSObject, UISearchBarDelegate {

        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }
    }
}

struct GrowingButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(.blue)
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 1.2 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}


// https://stackoverflow.com/a/56578995/17245189
func MD5(string: String) -> String {
    let digest = Insecure.MD5.hash(data: Data(string.utf8))

    return digest.map {
        String(format: "%02hhx", $0)
    }.joined()
}


extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        return Binding(
            get: { self.wrappedValue },
            set: { selection in
                self.wrappedValue = selection
                handler(selection)
        })
    }
}




struct ChapterWebView: UIViewRepresentable {

    var url: URL

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
        webView.scrollView.isScrollEnabled = true
    }
}



// an edited version of https://www.danijelavrzan.com/posts/2023/02/card-view-swiftui/
struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color("CardBackground"))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.1), radius: 4)
            .padding()
    }
}

// Container for card
// While using container, to align at top of page, you can this
// modifer on a VStack containing the Card and all other elements,
// typically inside groups such as a NavigationStack:
// .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
// This modifier will ensure that the card and all other elements will be aligned to the
// top of the page. For an example, check HomeView
struct Card<Content: View>: View {
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    var body: some View {
        VStack {
            HStack {
                Spacer()
                VStack {
                    content()
                }
                .padding()
                Spacer()
            }
            .cardBackground()
        }
    }
}


// -- main call api function --
func callApi(chapter: String, shloka: String) async -> Array<String> {
    do {
        var script = ""
        var meaning = ""
        let apis = [
            "English": "https://gita-api-v2.vercel.app/<c>/<s>",
            "Hindi": "https://gita-api-v2.vercel.app/hindi/<c>/<s>",
            "Telugu": "http://gita-api-v2.vercel.app/GitaTeluguAPIproxy/tel/<c>/<s>",
            "Odia": "http://gita-api-v2.vercel.app/GitaTeluguAPIproxy/odi/<c>/<s>"
        ]
        let (data, _) = try await URLSession.shared.data(from: URL(string: apis[UserDefaults.standard.string(forKey: "setlang") ?? "English"]!.replacingOccurrences(of: "<c>", with: chapter).replacingOccurrences(of: "<s>", with: shloka))!)
        let decodedResponse = try? JSONDecoder().decode(shlokrecive.self, from: data)
        meaning = decodedResponse?.meaning ?? "error_backup"
        script = decodedResponse?.script ?? "error_backup"
        if script == "error_backup" || meaning == "error_backup" {
            print("An error occured - using backup source")
            let (backup, _) = try await URLSession.shared.data(from: URL(string: "https://bhagavadgitaapi.in/slok/" + chapter + "/" + shloka + "/")!)
            let backupjson = try JSON(data: backup)
            let backupresult = [backupjson["transliteration"].stringValue, backupjson["purohit"]["et"].stringValue]
            script = backupresult[0]
            meaning = backupresult[1] + "\n\nUsing backup source"
        }
        if UserDefaults.standard.string(forKey: "langid") != "IAST" {
            let (newtext, _) = try await URLSession.shared.data(from: URL(string:"https://aksharamukha-plugin.appspot.com/api/public?source=IAST&target=\(UserDefaults.standard.string(forKey: "langid") ?? "IAST")&text=\(script.replacingOccurrences(of: "\n", with: "\\").addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "Error")")!)
            script = String(data: newtext, encoding: .utf8)!.replacingOccurrences(of: "\\", with: "\n")
        }
        let newvalue = TranslateLanguage(rawValue: UserDefaults.standard.object(forKey: "trlangid") as? String ?? "en")
        if newvalue != TranslateLanguage.english {
            meaning = try await translateText(meaning, language: newvalue)
        }
        
        return [script, meaning]
    }
    catch {
        return ["Jaya Guru Datta, looks like an error occurred...", "This may occur due to calling the shloka during loading. Please wait a few seconds and try again, or email me at jakkipally@gmail.com"]
    }
}
// -----------



func shlokaOfTheDay() async -> Array<String> {
    do {
        let (data, _) = try await URLSession.shared.data(from: URL(string: "https://gita-api-v2.vercel.app/shlokaoftheday")!)
        let json = try JSON(data: data)
        let shlokaNumber = [String(json[0].int!), String(json[1].int!)]
        let scripts = await callApi(chapter: shlokaNumber[0], shloka: shlokaNumber[1])
        return [scripts[0], scripts[1], shlokaNumber[0], shlokaNumber[1]]
    }
    catch {
        return ["Jaya Guru Datta, looks like an error occurred...", "This may occur occasionally. Please try again after some time, or email me at jakkipally@gmail.com", "", ""]
    }
}



struct HomeView: View {
    @State private var verse = "Getting verse... This may take some time..."
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    Card {
                        Text("Verse of the day\n")
                            .font(Font.body.weight(.bold))
                        Text(verse)
                            .task {
                                let verses = await shlokaOfTheDay()
                                verse = verses[0] + "\n\n" + verses[1] + "\n\nVerse number " + verses[2]+"." + verses[3]
                            }
                            .font(.system(size: 14))
                            .multilineTextAlignment(.center)
                    }
                    
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
            .navigationTitle("Home")
        }
    }
}




// Gita shlokas views ----

// Separate function for translating text using ML Kit Translate
func translateText(_ text: String, language: TranslateLanguage) async throws -> String {
    let options = TranslatorOptions(sourceLanguage: .english, targetLanguage: language)
    print(TranslateLanguage.telugu)
    let translateInstance = Translator.translator(options: options)
    
    let conditions = ModelDownloadConditions(
        allowsCellularAccess: true,
        allowsBackgroundDownloading: true
    )
    
    try await translateInstance.downloadModelIfNeeded(with: conditions)
    let translatedText = try await translateInstance.translate(text)
    
    return translatedText
}

struct GitaView: View {
    @State var shlokadd = "Loading..."
    @State var meaningadd = ""
    @State var chapter: String
    @State var shloka: String
    let shlokas = [
        "47",
        "72",
        "43",
        "42",
        "29",
        "47",
        "30",
        "28",
        "34",
        "42",
        "55",
        "20",
        "35",
        "27",
        "20",
        "24",
        "28",
        "78"
    ]
    @State var refresh: Bool = false
    @State var previousdisabled: Bool = false
    @State var nextdisabled: Bool = false
    @State private var shloksarr: Array<String> = []
    
    func update() {
       refresh.toggle()
    }
    
    @State private var titleshloka = ""
    var body: some View {
        VStack {
            //shloka and meaning
            Text(shlokadd)
                .task(id: refresh) {
                    titleshloka = shloka
                    var shloksarr2 = await callApi(chapter: chapter, shloka: shloka)
                    if chapter == "13" && shloka == "1" {
                        print("13 chapter 1st shloka found")
                        titleshloka = "0/1"
                        shloksarr2[1] = shloksarr2[1] + "\n\n This shloka is not universally found in all manuscripts. For simplicity, we set it as Shloka 1."
                    }
                    shlokadd = shloksarr2[0]
                    shloksarr = shloksarr2
                }
                .multilineTextAlignment(.center)
                .padding()
            if !shloksarr.isEmpty {
                Text(try! AttributedString(markdown: shloksarr[1], options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
                    .padding()
                    .multilineTextAlignment(.center)
            }
        }
            //audio
            WebView(url: URL(string: "https://bhagavdgita.github.io/ios/audioplayer.html?chapter=\(chapter)&shloka=\(shloka)")!)
                .frame(height: 100)
            
            // spacer
            Spacer()
            
            // next and previous
            HStack {
                    Button("Previous") {
                        self.nextdisabled = false
                        if Int(chapter) == 1 && Int(shloka) == 1 {
                            self.previousdisabled = true
                        } else {
                            if Int(shloka) == 1 {
                                self.chapter = String(Int(self.chapter)! - 1)
                                self.shloka = shlokas[Int(self.chapter)! - 1]
                                self.shlokadd = "Loading..."
                                self.shloksarr[1] = ""
                                self.update()
                            }
                            else {
                                self.shloka = String(Int(self.shloka)! - 1)
                                self.shlokadd = "Loading..."
                                self.shloksarr[1] = ""
                                self.update()
                            }
                        }
                        
                    }
                    .padding()
                    .disabled(previousdisabled == true)
                Spacer()
                Button("Next") {
                    self.previousdisabled = false
                    if Int(chapter) == 18 && Int(shloka) == 78 {
                        self.nextdisabled = true
                    } else {
                        if Int(shloka) == Int(shlokas[Int(chapter)! - 1]) {
                            self.chapter = String(Int(self.chapter)! + 1)
                            self.shloka = "1"
                            self.shlokadd = "Loading..."
                            self.shloksarr[1] = ""
                            self.update()
                        }
                        else {
                            self.shloka = String(Int(self.shloka)! + 1)
                            self.shlokadd = "Loading..."
                            self.shloksarr[1] = ""
                            self.update()
                        }
                    }
                }
                .padding()
                .disabled(nextdisabled == true)
            }
        .navigationTitle("Chapter \(chapter), Shloka \(titleshloka)")
        
}
}


struct shlokrecive: Codable {
    let script: String
    let meaning: String
}


struct ChooseShlok: View {
    @State private var chapter = "1"
    @State private var shloka = "1"
    let chapters = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18"]
    @State private var amountofshlokas = "47"
    let shlokas = [
        "47",
        "72",
        "43",
        "42",
        "29",
        "47",
        "30",
        "28",
        "34",
        "42",
        "55",
        "20",
        "35",
        "27",
        "20",
        "24",
        "28",
        "78"
    ]
    var body: some View {
        NavigationStack {
        VStack {
            HStack {
                
            Text("Chapter:")
            Picker("Choose a chapter:", selection: $chapter.onChange(bhagavadgitaChange)) {
                ForEach(chapters, id: \.self) {
                    Text($0)
                }
            }
            .pickerStyle(.menu)
            }
            HStack {
                Text("Shloka:")
                Picker("Choose a shloka:", selection: $shloka) {
                    ForEach(Array(1...Int(amountofshlokas)!).map{String($0)}, id: \.self) {
                        Text("\($0)")
                    }
                }
            }
            Text("Chapter \(chapter), Shloka \(shloka)")
            VStack {
                Spacer()
                NavigationLink(destination: GitaView(chapter: "\(chapter)", shloka: "\(shloka)")) {
                    Text("Go!")
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            
        }
        .navigationTitle("Gita - Shlokas")
        }
        
        
    }
    func bhagavadgitaChange(_ tag: String) {
        amountofshlokas = shlokas[Int(tag)! - 1]
        shloka = "1"
    }
}


// ---------

// chapter full
struct ChapterFull: View {
    var chapters = ["Full Bhagavad Gita", "Dhyana Shlokas", "Chapter 1", "Chapter 2", "Chapter 3", "Chapter 4", "Chapter 5", "Chapter 6", "Chapter 7", "Chapter 8", "Chapter 9", "Chapter 10", "Chapter 11", "Chapter 12", "Chapter 13", "Chapter 14", "Chapter 15", "Chapter 16", "Chapter 17", "Chapter 18", "Gita Mahatmyam", "Gita Saram"]
    @State private var selectedChapter = "Full Bhagavad Gita"
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Please choose a chapter", selection: $selectedChapter) {
                    ForEach(chapters, id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(.wheel)
                Spacer()
                NavigationLink(destination: ShowChapter(chapter: selectedChapter)) {
                    Text("Go!")
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            .navigationTitle("Gita - Chapters/Full")
        }
        
    }
    
}

struct ShowChapter: View {
    @State var chapter: String
    var chapters = [
        "Dhyana Shlokas": "dhyana",
        "Chapter 1": "1",
        "Chapter 2": "2",
        "Chapter 3": "3",
        "Chapter 4": "4",
        "Chapter 5": "5",
        "Chapter 6": "6",
        "Chapter 7": "7",
        "Chapter 8": "8",
        "Chapter 9": "9",
        "Chapter 10": "10",
        "Chapter 11": "11",
        "Chapter 12": "12",
        "Chapter 13": "13",
        "Chapter 14": "14",
        "Chapter 15": "15",
        "Chapter 16": "16",
        "Chapter 17": "17",
        "Chapter 18": "18",
        "Full Bhagavad Gita": "gita",
        "Gita Mahatmyam": "mahatmyam",
        "Gita Saram": "saram"
    ]
    var body: some View {
        WebView(url: URL(string: "https://bhagavdgita.github.io/ios/chapaudio.html?chapter=\(chapters[chapter] ?? "nil")".replacingOccurrences(of: " ", with: "%20", options: .literal, range: nil))!)
            .frame(height: 40)
        ChapterWebView(url: URL(string: "https://bhagavdgita.github.io/chapterscripts/\(chapter).pdf".replacingOccurrences(of: " ", with: "%20", options: .literal, range: nil))!)
                .navigationBarTitle("\(chapter)")
    }
}


// ---------

struct Account: View {
    @State private var showingAlert = false
    @State var user = ""
    @State var email = ""
    @State var refresh: Bool = false
    @State var credentialsManager = CredentialsManager(authentication: Auth0.authentication())
    @State var accessToken = ""
    var hasValidCredentials: Bool {
            credentialsManager.hasValid()
    }
    @State private var showDestinationView = false
    var body: some View {
        
                        if hasValidCredentials {
                            LoggedIn()
                        } else {
                            NavigationStack {
                                
                                Text("Gita Account")
                                    .font(Font.system(size: 50).weight(.bold))
                                Image("Rocket")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 200, height: 200)
                                Text("Personalize the app and get language features by creating a account. It's ***free***!")
                                    .padding()
                                    .multilineTextAlignment(.center)
                                Button(action: {
                                    print(hasValidCredentials)
                                    Auth0
                                        .webAuth()
                                        .audience("https://dev-1lh8f0uy7cxikoik.us.auth0.com/api/v2/")
                                        .start { result in
                                            switch result {
                                            case .success(let credentials):
                                                print("Obtained credentials: \(credentials)")
                                                _ = credentialsManager.store(credentials: credentials)
                                                showDestinationView.toggle()
                                            case .failure(_):
                                                showingAlert = true
                                            }
                                        }
                                }) {
                                    Text("Log in or Sign Up")
                                        .font(Font.system(size: 30).weight(.bold))
                                }
                                .navigate(using: $showDestinationView) { LoggedIn() }
                            }
                        }
                            
                    }
                    
            
    }

struct LoggedIn: View {
    @State var user = ""
    @State var textUser = ""
    @State var email = ""
    @State var credentialsManager = CredentialsManager(authentication: Auth0.authentication())
    var hasValidCredentials: Bool {
            credentialsManager.hasValid()
    }
    @State private var showDestinationView = false
    // dark mode suppot ----
    @AppStorage("isDarkMode") private var isDarkMode = false
    // languages -----
    @AppStorage("lang") private var language = "Roman/English (IAST)"
    @AppStorage("langid") private var languageid = "IAST"
    @State private var searchTerm: String = ""
    let languagesid = ["Ahom","Arab","Ariyaka","Assamese","Avestan","Balinese","BatakKaro","BatakManda","BatakPakpak","BatakSima","BatakToba","Bengali","Bhaiksuki","Brahmi","Buginese","Buhid","Burmese","Chakma","Cham","RussianCyrillic","Devanagari","Dogra","Elym","Ethi","GunjalaGondi","MasaramGondi","Grantha","GranthaPandya","Gujarati","Hanunoo","Hatr","Hebrew","Hebr-Ar","Armi","Phli","Prti","Hiragana","Katakana","Javanese","Kaithi","Kannada","Kawi","KhamtiShan","Kharoshthi","Khmer","Khojki","KhomThai","Khudawadi","Lao","LaoPali","Lepcha","Limbu","Mahajani","Makasar","Malayalam","Mani","Marchen","MeeteiMayek","Modi","Mon","Mongolian","Mro","Multani","Nbat","Nandinagari","Newa","Narb","OldPersian","Sogo","Sarb","Oriya","Pallava","Palm","Arab-Fa","PhagsPa","Phnx","Phlp","Gurmukhi","Ranjana","Rejang","HanifiRohingya","BarahaNorth","BarahaSouth","RomanColloquial","PersianDMG","HK","IAST","IASTPali","IPA","ISO","ISOPali","ISO233","ISO259","Itrans","IASTLOC","RomanReadable","HebrewSBL","SLP1","Type","Latn","Titus","Velthuis","WX","Samr","Santali","Saurashtra","Shahmukhi","Shan","Sharada","Siddham","Sinhala","Sogd","SoraSompeng","Soyombo","Sundanese","SylotiNagri","Syrn","Syre","Syrj","Tagalog","Tagbanwa","TaiLaing","Takri","Tamil","TamilExtended","TamilBrahmi","Telugu","Thaana","Thai","TaiTham","LaoTham","KhuenTham","LueTham","Tibetan","Tirhuta","Ugar","Urdu","Vatteluttu","Wancho","WarangCiti","ZanabazarSquare"]
    let languages = ["Ahom","Arabic","Ariyaka","Assamese","Avestan","Balinese","Batak Karo","Batak Mandailing","Batak Pakpak","Batak Simalungun","Batak Toba","Bengali (Bangla)","Bhaiksuki","Brahmi","Buginese (Lontara)","Buhid","Burmese (Myanmar)","Chakma","Cham","Cyrillic (Russian)","Devanagari","Dogra","Elymaic","Ethiopic (Abjad)","Gondi (Gunjala)","Gondi (Masaram)","Grantha","Grantha (Pandya)","Gujarati","Hanunoo","Hatran","Hebrew","Hebrew (Judeo-Arabic)","Imperial Aramaic","Inscriptional Pahlavi","Inscriptional Parthian","Japanese (Hiragana)","Japanese (Katakana)","Javanese","Kaithi","Kannada","Kawi","Khamti Shan","Kharoshthi","Khmer (Cambodian)","Khojki","Khom Thai","Khudawadi","Lao","Lao (Pali)","Lepcha","Limbu","Mahajani","Makasar","Malayalam","Manichaean","Marchen","Meetei Mayek (Manipuri)","Modi","Mon","Mongolian (Ali Gali)","Mro","Multani","Nabataean","Nandinagari","Newa (Nepal Bhasa)","Old North Arabian","Old Persian","Old Sogdian","Old South Arabian","Oriya (Odia)","Pallava","Palmyrene","Persian","PhagsPa","Phoenician","Psalter Pahlavi","Punjabi (Gurmukhi)","Ranjana (Lantsa)","Rejang","Rohingya (Hanifi)","Roman (Baraha North)","Roman (Baraha South)","Roman (Colloquial)","Roman (DMG Persian)","Roman (Harvard-Kyoto)","Roman/English (IAST)","Roman (IAST: Pāḷi)","Roman (IPA Indic)","Roman (ISO 15919 Indic)","Roman (ISO 15919: Pāḷi)","Roman (ISO 233 Arabic)","Roman (ISO 259 Hebrew)","Roman (ITRANS)","Roman (LoC Burmese)","Roman (Readable)","Roman (SBL Hebrew)","Roman (SLP1)","Roman (Semitic Typeable)","Roman (Semitic)","Roman (Titus)","Roman (Velthuis)","Roman (WX)","Samaritan","Santali (Ol Chiki)","Saurashtra","Shahmukhi","Shan","Sharada","Siddham","Sinhala","Sogdian","Sora Sompeng","Soyombo","Sundanese","Syloti Nagari","Syriac (Eastern)","Syriac (Estrangela)","Syriac (Western)","Tagalog","Tagbanwa","Tai Laing","Takri","Tamil","Tamil (Extended)","Tamil Brahmi","Telugu","Thaana (Dhivehi)","Thai","Tham (Lanna)","Tham (Lao)","Tham (Tai Khuen)","Tham (Tai Lue)","Tibetan","Tirhuta (Maithili)","Ugaritic","Urdu","Vatteluttu","Wancho","Warang Citi","Zanabazar Square"]
    var filteredLang: [String] {
            languages.filter {
                searchTerm.isEmpty ? true : $0.lowercased().contains(searchTerm.lowercased())
            }
        }
    // -------translate----------
    let transationlangs = ["Afrikaans","Arabic","Belarusian","Bulgarian","Bengali","Catalan","Czech","Welsh","Danish","German","Greek","English","Esperanto","Spanish","Estonian","Persian","Finnish","French","Irish","Galician","Gujarati","Hebrew","Hindi","Croatian","Haitian","Hungarian","Indonesian","Icelandic","Italian","Japanese","Georgian","Kannada","Korean","Lithuanian","Latvian","Macedonian","Marathi","Malay","Maltese","Dutch","Norwegian","Polish","Portuguese","Romanian","Russian","Slovak","Slovenian","Albanian","Swedish","Swahili","Tamil","Telugu","Thai","Tagalog","Turkish","Ukrainian","Urdu","Vietnamese","Chinese"]
    let transationlangid = [TranslateLanguage.afrikaans,TranslateLanguage.arabic,TranslateLanguage.belarusian,TranslateLanguage.bulgarian,TranslateLanguage.bengali,TranslateLanguage.catalan,TranslateLanguage.czech,TranslateLanguage.welsh,TranslateLanguage.danish,TranslateLanguage.german,TranslateLanguage.greek,TranslateLanguage.english,TranslateLanguage.eperanto,TranslateLanguage.spanish,TranslateLanguage.estonian,TranslateLanguage.persian,TranslateLanguage.finnish,TranslateLanguage.french,TranslateLanguage.irish,TranslateLanguage.galician,TranslateLanguage.gujarati,TranslateLanguage.hebrew,TranslateLanguage.hindi,TranslateLanguage.croatian,TranslateLanguage.haitianCreole,TranslateLanguage.hungarian,TranslateLanguage.indonesian,TranslateLanguage.icelandic,TranslateLanguage.italian,TranslateLanguage.japanese,TranslateLanguage.georgian,TranslateLanguage.kannada,TranslateLanguage.korean,TranslateLanguage.lithuanian,TranslateLanguage.latvian,TranslateLanguage.macedonian,TranslateLanguage.marathi,TranslateLanguage.malay,TranslateLanguage.maltese,TranslateLanguage.dutch,TranslateLanguage.norwegian,TranslateLanguage.polish,TranslateLanguage.portuguese,TranslateLanguage.romanian,TranslateLanguage.russian,TranslateLanguage.slovak,TranslateLanguage.slovenian,TranslateLanguage.albanian,TranslateLanguage.swedish,TranslateLanguage.swahili,TranslateLanguage.tamil,TranslateLanguage.telugu,TranslateLanguage.thai,TranslateLanguage.tagalog,TranslateLanguage.turkish,TranslateLanguage.ukrainian,TranslateLanguage.urdu,TranslateLanguage.vietnamese,TranslateLanguage.chinese]
    @State private var trSearchTerm: String = ""
    var filteredTrLang: [String] {
        transationlangs.filter {
            trSearchTerm.isEmpty ? true : $0.lowercased().contains(trSearchTerm.lowercased())
        }
    }
    @AppStorage("trlang") private var trlanguage = "English"
    @AppStorage("trlangid") private var trlanguageid = TranslateLanguage.english
    
    // real scripts
    @AppStorage("setlang") private var setlang = "English"
    var avallang = ["English", "Hindi", "Telugu", "Odia"]
    var body: some View {
        NavigationStack {
            Form {
                // --------- user information -----------
                HStack {
                    // profile info
                    AsyncImage(url: URL(string: "https://www.gravatar.com/avatar/\(MD5(string: email))?r=g&d=https%3A%2F%2Fbhagavdgita.github.io%2Fdhanvantari_6373533.png&s=60"))
                        .clipShape(Circle())
                        .task {
                            credentialsManager.credentials { result in
                                switch result {
                                case .success(_):
                                    email = (credentialsManager.user?.email)!
                                    print("SUCCESS: got email \(email)")
                                    print("--------- credentials --------")
                                    print(credentialsManager)
                                    print("------------------------------")
                                case .failure(let error):
                                    print("Failed with: \(error)")
                                    // go back to login
                                    showDestinationView.toggle()
                                }
                            }
                        }
                    Spacer()
                    Text(user)
                        .task {
                            credentialsManager.credentials { result in
                                switch result {
                                case .success(_):
                                    user = (credentialsManager.user?.name)!
                                    textUser = (credentialsManager.user?.name)!
                                case .failure(let error):
                                    print("ERROR: Failed with: \(error)")
                                }
                            }
                        }
                    
                }
                
                Link("Set a profile picture", destination: URL(string: "https://en.gravatar.com/")!)
                
                Section(header: Text("PERSONALIZATION")) {
                    Toggle("Dark Mode", isOn: $isDarkMode)
                    
                    Picker("Language", selection: $setlang) {
                        ForEach(avallang, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    .onChange(of: setlang) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "setlang")
                    }
                }
                
                // ------------- end user information -----------
                // ------------- account preferences ------------
                Section(header: Text("BETA"), footer: Text("These translations/scripts are almost always inaccurate, as translated by a translation service/script converter. We plan to improve this in the future. In the meantime, we recommend looking for your language in the \"Language\" section of this app")) {
                    Picker("Script Conversion", selection: $language) {
                        SearchBar(text: $searchTerm, placeholder: "Search Languages")
                        ForEach(filteredLang, id: \.self) {
                            Text($0)
                        }
                        let _ = print(language)
                    }
                    .pickerStyle(.navigationLink)
                    .onChange(of: language) { newValue in
                        UserDefaults.standard.set(self.language, forKey: "lang")
                        print(languagesid[languages.firstIndex(of: self.language)!])
                        UserDefaults.standard.set(languagesid[languages.firstIndex(of: self.language)!], forKey: "langid")
                    }
                    // translation
                    Picker("Translate Meanings", selection: $trlanguage) {
                        SearchBar(text: $trSearchTerm, placeholder: "Search Translations")
                        ForEach(filteredTrLang, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    .onChange(of: trlanguage) { newValue in
                        UserDefaults.standard.set(self.trlanguage, forKey: "trlang")
                        UserDefaults.standard.set(transationlangid[transationlangs.firstIndex(of: self.trlanguage)!], forKey: "trlangid")
                    }

                }
                
                // ----------
                Section(header: Text("Other Settings")) {
                    // ------------- start button for logout ---------------
                    Button(action: {
                        Auth0
                            .webAuth()
                            .clearSession { result in
                                switch result {
                                case .success:
                                    print("SUCCESS: Logged out")
                                    showDestinationView.toggle()
                                case .failure(let error):
                                    print("ERROR: Failed with: \(error)")
                                }
                            }
                        _ = credentialsManager.clear()
                        
                    }) {
                        Text("Logout")
                    }
                    .navigate(using: $showDestinationView) { Account() }
                    
                    // --------- end of button for logout ------------
                }
                
                
                
                
                
                // ------------------------ form end -----------------------------
            }           // end of form
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.large)
            }
            
        }
        
    }





// ---------
// Main struct
struct ContentView: View {
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var isPresented = false
    var body: some View {
        if networkMonitor.isConnected {
            TabView {
                    HomeView()
                        .tabItem {
                            Image(systemName: "house")
                            Text("Home")
                        }
                    
                    ChooseShlok()
                        .tabItem {
                            Image(systemName: "text.book.closed")
                            Text("Shlokas")
                        }
                    ChapterFull()
                        .tabItem {
                            Image(systemName: "books.vertical")
                            Text("Chapters")
                        }
                    Account()
                        .tabItem {
                            Image(systemName: "person.crop.circle")
                            Text("Account")
                        }
                }
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .tint(.cyan)
        } else {
            // No wifi :( (Time for tea)
            VStack {
                Spacer()
                Image(systemName: "cup.and.saucer.fill").foregroundColor(.brown).font(.system(size: 60))
                Text("Error 418").font(.system(size: 30, weight: .heavy, design: .default))
                Text("The server refuses to brew coffee :(")
                Text("\"I'm a teapot!\"")
                Group {
                    Spacer()
                    Text("Tip me over and pour me out!").font(.system(size: 12))
                    Text("No Internet").font(.system(size: 12))
                    Spacer()
                    Spacer()
                }
                Button {
                    isPresented.toggle()
                } label: {
                    Text("Retry to connect")
                }
                .buttonStyle(.borderedProminent)
            }
            .font(.system(size: 20))
            .fullScreenCover(isPresented: $isPresented) {
                extraView()
            }
        }
        
    }
}


// navigation binding
extension View {
    func navigate<Destination: View>(using binding: Binding<Bool>, destination: () -> Destination) -> some View {
        background(
            NavigationLink(
                destination: destination()
                    .navigationBarBackButtonHidden(true)
                    .navigationBarTitleDisplayMode(.large),
                isActive: binding,
                label: { EmptyView() }
            )
            .hidden()
        )
    }
    
    func cardBackground() -> some View {
            modifier(CardBackground())
    }
}


// previews!!
struct extraView: View {
    @StateObject var networkMonitor = NetworkMonitor()
    var body: some View {
        ContentView()
            .environmentObject(networkMonitor)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        extraView()
    }
}
