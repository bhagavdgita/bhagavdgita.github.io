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

// UIViewRepresentables
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





struct HomeView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    HStack {
                        Spacer()
                        ZStack {
                            Text("Welcome").font(.largeTitle)
                        }
                        Spacer()
                    }
                }
            }
        .navigationTitle("Home")
        }
    }
}




// Gita shlokas views ----

func callApi(chapter: String, shloka: String) async -> Array<String> {
    do {
        var script = ""
        var meaning = ""
        if UserDefaults.standard.string(forKey: "langid") == "IAST" {
            print("using original text")
            let (data, _) = try await URLSession.shared.data(from: URL(string:"https://bhagavadgitaapi.in/slok/\(chapter)/\(shloka)/")!)
            let decodedResponse = try? JSONDecoder().decode(shlokrecive.self, from: data)
            meaning = decodedResponse?.purohit.et ?? ""
            script = decodedResponse?.transliteration ?? ""
        } else {
            let (data, _) = try await URLSession.shared.data(from: URL(string:"https://bhagavadgitaapi.in/slok/\(chapter)/\(shloka)/")!)
            let decodedResponse = try? JSONDecoder().decode(shlokrecive.self, from: data)
            let text = decodedResponse?.purohit.et ?? ""
            let text2 = decodedResponse?.transliteration ?? ""
            let (newtext, _) = try await URLSession.shared.data(from: URL(string:"https://aksharamukha-plugin.appspot.com/api/public?source=IAST&target=\(UserDefaults.standard.string(forKey: "langid") ?? "IAST")&text=\(text2.replacingOccurrences(of: "\n", with: "\\").addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "Error")")!)
            script = String(data: newtext, encoding: .utf8)!.replacingOccurrences(of: "\\", with: "\n")
            meaning = text
        }
        let newvalue = TranslateLanguage(rawValue: UserDefaults.standard.object(forKey: "trlangid") as? String ?? "en")
        if newvalue != TranslateLanguage.english {
            meaning = try await translateText(meaning, language: newvalue)
        }
        
        return [script, meaning]
    }
    catch {
        return ["Error in calling shloka...", "Wait for a few seconds and try again"]
    }
}

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
    var body: some View {
        VStack {
            //shloka and meaning
            Text(shlokadd)
                .task(id: refresh) {
                    shloksarr = await callApi(chapter: chapter, shloka: shloka)
                    shlokadd = shloksarr[0]
                }
                .padding()
            
            if !shloksarr.isEmpty {
                Text(shloksarr[1])
                    .padding()
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
                                self.meaningadd = ""
                                self.update()
                            }
                            else {
                                self.shloka = String(Int(self.shloka)! - 1)
                                self.shlokadd = "Loading..."
                                self.meaningadd = ""
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
                            self.meaningadd = ""
                            self.update()
                        }
                        else {
                            self.shloka = String(Int(self.shloka)! + 1)
                            self.shlokadd = "Loading..."
                            self.meaningadd = ""
                            self.update()
                        }
                    }
                }
                .padding()
                .disabled(nextdisabled == true)
            }
            }
        .navigationTitle("Chapter \(chapter), Shloka \(shloka)")
        
}
}


struct shlokrecive: Codable {
    let transliteration: String
    let purohit: Purohit
}

struct Purohit: Codable {
    let et: String
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
                Spacer()
            }
            
        }
        .navigationTitle("Gita - Shlokas")
        }
        
        
    }
    func bhagavadgitaChange(_ tag: String) {
        amountofshlokas = shlokas[Int(tag)! - 1]
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
                Spacer()
            }
            .navigationTitle("Gita - Chapters/Full")
        }
        
    }
    
}

struct ShowChapter: View {
    @State var chapter: String
    
    var body: some View {
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
                                    Text("Login/Signup")
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
    // languages -----
    @AppStorage("lang") private var language = "Roman (IAST)"
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
                
                // ------------- end user information -----------
                // ------------- account preferences ------------
                Section(header: Text("BETA"), footer: Text("These translations are almost always inaccurate, as translated by a translation service. We plan to improve this in the future")) {
                    Picker("Script", selection: $language) {
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
                        print(UserDefaults.standard.object(forKey: "trlangid"))
                    }

                }
                
                // ----------
                Section(header: Text("Other Settings")) {
                    // ------------- start button ---------------
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
            }
            .font(.system(size: 20))

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
}
