function undisable() {
	document.getElementById("qlmz").removeAttribute("disabled")
}


setInterval(() => {
	if (parseInt(localStorage.getItem("c")) < new Date().getDate()) {
    	console.log("day is over")
        undisable()
    }
}, 500)

function updateshlok() {
	document.getElementById("changephrase").innerHTML = "Finished"
    document.getElementById("removequestion").innerHTML = ""
	document.getElementById("qlmz").disabled = "true"
    const d = new Date();
    var c = d.getDate()
    localStorage.setItem("c", String(c))
    localStorage.setItem("timesfinished", String(parseInt(localStorage.getItem("timesfinished")) + 1))
    document.getElementById("current").innerHTML = String(parseInt(    document.getElementById("current").innerHTML) + 1)
	console.log("Finished shlokas for today")
	var listshlokas = ["0", "47", "72", "43", "42", "29", "47", "30", "28", "34", "42", "55", "20", "35", "27", "20", "24", "28", "78"]
    var shlokascomplete = [localStorage.getItem("shlok").split(".")[0], localStorage.getItem("shlok").split(".")[1]]
    document.getElementById("shlokasdone").value = String(parseInt(document.getElementById("shlokasdone").value) + parseInt(localStorage.getItem("journey")))
    if (localStorage.getItem("shlok").split(".")[1] == listshlokas[localStorage.getItem("shlok").split(".")[0]]) {
    	localStorage.setItem("shlok", String(parseInt(localStorage.getItem("shlok").split(".")[0]) + 1) + ".1")
    } else {
    
    if (parseInt(localStorage.getItem("shlok").split(".")[1]) + parseInt(localStorage.getItem("journey")) > parseInt(listshlokas[localStorage.getItem("shlok").split(".")[0]])) {
    
    localStorage.setItem("shlok", String(parseInt(localStorage.getItem("shlok").split(".")[0]) + 1) + "." + String(parseInt(localStorage.getItem("shlok").split(".")[1]) + parseInt(localStorage.getItem("journey")) - parseInt(listshlokas[localStorage.getItem("shlok").split(".")[0]])))
    	
        } else {
        localStorage.setItem("shlok", localStorage.getItem("shlok").split(".")[0] + "." + String(parseInt(localStorage.getItem("shlok").split(".")[1]) + parseInt(localStorage.getItem("journey"))))
        }
    }
    if (localStorage.getItem("shlok").split(".")[0] == "19")
    {
    	document.getElementById("donetoday").innerHTML = "You are done with the full journey. Congrats, you read the full Bhagavad Gita! Next read the Gita Mahatmyam."
        document.getElementById("firstassignedbutton").disabled = "true"
        document.getElementById("qwerty").style = "display: block;"
    }
    
    localStorage.setItem("progress", document.getElementById("shlokasdone").value)
}

function gotoshlok() {
	document.getElementById("dashboard").style = "display: none;"
    document.getElementById("chapter").value = localStorage.getItem("shlok").split(".")[0]
    getchapter()
    document.getElementById("shloka").value = localStorage.getItem("shlok").split(".")[1]
    getshloka()
    document.getElementById("read").style = "display: block;"
}


  
function startjourney() {
	document.getElementById("startjourneybutton").style = "display: none;"
    document.getElementById("journeyinprogress").style = "display: block;"
    document.getElementById("shlokasdone").value = "0"
    localStorage.setItem("timesfinished", "0")
    localStorage.setItem("journeystarted", "true")
}
function startjourney28() {
	startjourney()
	localStorage.setItem('journey', '26');
    localStorage.setItem('journey1', '28');
    localStorage.setItem('shlok', '1.1');
    document.getElementById("end").innerHTML = "28"
    document.getElementById("shlokasfortoday").innerHTML = "26"
}

function startjourney366() {
	startjourney()
    localStorage.setItem('journey', '2');
    localStorage.setItem('journey1', '365');
    localStorage.setItem('shlok', '1.1');
    document.getElementById("end").innerHTML = "365"
    document.getElementById("shlokasfortoday").innerHTML = "2"
}

function restartjourney() {
Swal.fire({
  title: 'Erase journey?',
  text: "You won't be able to revert this",
  type: 'warning',
  showCancelButton: true,
  confirmButtonColor: '#3085d6',
  cancelButtonColor: '#d33',
  confirmButtonText: `<span style="font-family: 'Roboto';">Erase</span>`,
  cancelButtonText: `<span style="font-family: 'Roboto';">Cancel</span>`
}).then((result) => {
  if (result.value) {
    localStorage.clear();
    window.location.reload();
  }
})
	
    
}

if (localStorage.getItem("journeystarted") == "true") {
	console.log("journey has started")
    document.getElementById("startjourneybutton").style = "display: none;"
    document.getElementById("journeyinprogress").style = "display: block;"
    var times = localStorage.getItem("timesfinished");
    localStorage.setItem("shlok", "1.1")
    localStorage.setItem("timesfinished", "0")
    for(var i = 0; i < parseInt(times); i++){
        updateshlok()
    }
    document.getElementById("end").innerHTML = localStorage.getItem("journey1")
} else {
	console.log("no journey\ndetected by using journeystarted in storage")
}


var showbackpage = ""


function fullaudio() {
	document.getElementById("invisible-audio").innerHTML = `
	<audio controls>
	<source src="https://bhagavdgita.github.io/audio/full.${document.getElementById("chapter").value}.m4a" type="audio/x-m4a">
  <code> Your phone doesn't support audio tags</code>
</audio>
    `
}


function readbhagavadgita() {
	showbackpage = "options"
	document.getElementById("options").style = "display: none;"
    document.getElementById("read").style = "display: block;"
}



var e = document.getElementById("chapter");
function onChange() {
  var value = e.value;
  var text = e.options[e.selectedIndex].text;
  console.log(value);
  getchapter();
}
e.onchange = onChange;


var chapter = ""
function getchapter() {
	
    
    extras = ["dhyana", "aarati", "saaram", "maha"]
    
    function myNewFunction(sel) {
  return sel.options[sel.selectedIndex].text;
}
    if (extras.includes(document.getElementById("chapter").value)) {
    	console.log("viewing one of the following:")
        console.log(extras)
    	showbackpage = "nooptions"
    	document.getElementById("chapterstest").style = "display: none;"
        document.getElementById("extrasshow").style = "display: block;"
        document.getElementById("chapteradd3").innerHTML = myNewFunction(document.getElementById("chapter"))
        fetch('https://bhagavdgita.github.io/text/' + document.getElementById("chapter").value + ".txt")
	.then(response => response.text())
	.then(response => {
        document.getElementById("theshlokas1").innerHTML = response.replaceAll("\n", "<br>")
        document.getElementById("theaudio3").innerHTML = `
	<audio controls>
	<source src="https://bhagavdgita.github.io/audio/full.${document.getElementById("chapter").value}.m4a" type="audio/x-m4a">
  <code> Your phone doesn't support audio tags</code>
</audio>
    `
      })
    } else {
    
	var chapter = document.getElementById("chapter").value
    var listshlokas = ["0", "47", "72", "43", "42", "29", "47", "30", "28", "34", "42", "55", "20", "35", "27", "20", "24", "28", "78"]
    	document.getElementById("chapterstest").style = "display: block;"
    	document.getElementById("shlokasting").style = "display: block;"
        document.getElementById("shloka").innerHTML = `<option value="" selected disabled hidden>Choose</option>`
        for (var i = 1; i < parseInt(listshlokas[chapter]) + 1; i++) {
          createnewoption = document.createElement("option")
          createnewoption.innerHTML = i.toString()
          createnewoption.value = i.toString()
          test = document.getElementById("shloka")
          test.appendChild(createnewoption)
        }
     var e = document.getElementById("shloka");
function onChange() {
  var value = e.value;
  var text = e.options[e.selectedIndex].text;
  console.log(value);
  getshloka();
}
e.onchange = onChange;
}
}



function getall() {
showbackpage = "nooptions"
var shloka = document.getElementById("shloka").value
document.getElementById("shlokasting").style = "display: none;"
    document.getElementById("chapterstest").style = "display: none;"
    document.getElementById("fullchapter").style = "display: block;"
    	document.getElementById("chapteradd2").innerHTML = document.getElementById("chapter").value
    const options = {
	method: 'GET',
	headers: {
		'X-RapidAPI-Key': '72ddb23f61mshd7034341804bcedp12906djsned505dec18e5',
		'X-RapidAPI-Host': 'bhagavad-gita3.p.rapidapi.com'
	}
};

fetch('https://bhagavad-gita3.p.rapidapi.com/v2/chapters/' + document.getElementById("chapter").value + '/verses/', options)
	.then(response => response.json())
	.then(response => {
    function replaceAllButLast(str, pOld, pNew) {
  var parts = str.split(pOld)
  if (parts.length === 1) return str
  return parts.slice(0, -1).join(pNew) + pOld + parts.slice(-1)
}
    	var shloka = 1
    	var result = ""
    	response.forEach(item => {
        	result = result + replaceAllButLast(item.transliteration, "\n", "<br>")
            result = result +  `||${document.getElementById("chapter").value}.${String(shloka)}||<br><br>`
            shloka ++
        })
        document.getElementById("theshlokas").innerHTML = result;
        
        
    })
	.catch(err => console.error(err));
}

function getshloka() {
	showbackpage = "nooptions"
	var shloka = document.getElementById("shloka").value
    
    if (shloka == "all") {
    
    
    
    getall()
    
    
    
    
    } else {
    
    document.getElementById("shlokasting").style = "display: none;"
    document.getElementById("chapterstest").style = "display: none;"
    document.getElementById("finalshloka").style = "display: block;"
    document.getElementById("chapteradd1").innerHTML = document.getElementById("chapter").value
    document.getElementById("shlokadd").innerHTML = shloka
    
    // get shloka from api

    const options = {
	method: 'GET',
	headers: {
		'X-RapidAPI-Key': '72ddb23f61mshd7034341804bcedp12906djsned505dec18e5',
		'X-RapidAPI-Host': 'bhagavad-gita3.p.rapidapi.com'
	}
};

fetch('https://bhagavad-gita3.p.rapidapi.com/v2/chapters/' + document.getElementById("chapter").value + '/verses/' + shloka + '/', options)
	.then(response => response.json())
	.then(response => {
    document.getElementById("theshloka").innerHTML = response.transliteration.replaceAll('\n', '<br>')
    document.getElementById("themeaning").innerHTML = "<br><br>" +  response.translations[0].description.replaceAll('\n', '<br>') + `<br>
<audio controls>
	<source src="https://bhagavdgita.github.io/audio/${document.getElementById("chapter").value}.${shloka}.m4a" type="audio/x-m4a">
  <code> Your phone doesn't support audio tags</code>
</audio>`
    })
	.catch(err => console.error(err));
    }
} 


function gotoback() {
	var listshlokas = ["0", "47", "72", "43", "42", "29", "47", "30", "28", "34", "42", "55", "20", "35", "27", "20", "24", "28", "78"]
	var shloka = document.getElementById("shloka").value
    var chapter = document.getElementById("chapter").value
    document.getElementById("theshloka").innerHTML = "Loading... Please wait"
    document.getElementById("themeaning").innerHTML = ""
    if (shloka == 1) {
    	document.getElementById("shloka").value = listshlokas[parseInt(chapter) - 1]
        document.getElementById("chapter").value = parseInt(chapter) - 1
        console.log(document.getElementById("chapter").value)
        console.log(document.getElementById("shloka").value)
        getshloka()
    } else {
    	document.getElementById("shloka").value = parseInt(shloka) - 1
        getshloka()
    }
}

function gottofront() {
	var listshlokas = ["0", "47", "72", "43", "42", "29", "47", "30", "28", "34", "42", "55", "20", "35", "27", "20", "24", "28", "78"]
	var shloka = document.getElementById("shloka").value
    var chapter = document.getElementById("chapter").value
    document.getElementById("theshloka").innerHTML = "Loading... Please wait"
    document.getElementById("themeaning").innerHTML = ""
    if (shloka == parseInt(listshlokas[chapter])) {
    	document.getElementById("shloka").value = 1
        document.getElementById("chapter").value = parseInt(chapter) + 1
        console.log(document.getElementById("chapter").value)
        console.log(document.getElementById("shloka").value)
        getshloka()
    } else {
    	document.getElementById("shloka").value = parseInt(shloka) + 1
        getshloka()
    }
}

function gohome1() {
		if (showbackpage == "options") {
			
            document.getElementById("finalshloka").style = "display: none;"
        	document.getElementById("shlokasting").style = "display: none;"
        	document.getElementById("chapterstest").style = "display: block;"
            document.getElementById("extrasshow").style = "display: none;"
        	document.getElementById("fullchapter").style = "display: none;"
        	document.getElementById("read").style = "display: none;"
            document.getElementById("options").style = "display: block;"
        } else {
        	document.getElementById("finalshloka").style = "display: none;"
        	document.getElementById("shlokasting").style = "display: none;"
        	document.getElementById("chapterstest").style = "display: block;"
            document.getElementById("extrasshow").style = "display: none;"
        	document.getElementById("fullchapter").style = "display: none;"
        	document.getElementById("read").style = "display: block;"
            document.getElementById("options").style = "display: none;"
            document.getElementById("chapter").value = ""
            showbackpage = "options"
        }
}


function dashboard() {
	document.getElementById("options").style = "display: none;"
    document.getElementById("dashboard").style = "display: block;"
	
    // verse of day  			
    fetch("https://gitaapprandomshlokagen.arjunjakkipally.repl.co")
    .then(response => response.json())
    .then((data) => {
const options = {
	method: 'GET',
	headers: {
		'X-RapidAPI-Key': '72ddb23f61mshd7034341804bcedp12906djsned505dec18e5',
		'X-RapidAPI-Host': 'bhagavad-gita3.p.rapidapi.com'
	}
};

fetch('https://bhagavad-gita3.p.rapidapi.com/v2/chapters/' + data[0] + '/verses/' + data[1] + '/', options)
	.then(response => response.json())
	.then(response => {
    document.getElementById("verseofday").innerHTML = response.transliteration.replaceAll('\n', '<br>')
    
    document.getElementById("meaning").innerHTML = "<br><br>" +  response.translations[0].description.replaceAll('\n', '<br>')
    })
	.catch(err => console.error(err));
    })
}	


function shareverse() {
	
if (navigator.share) {
  navigator.share({
      title: 'Verse of the day',
      text: document.getElementById("verseofday").innerText + document.getElementById("meaning").innerText
    }).then(() => {
      console.log('Thanks for sharing!');
    })
    .catch(console.error);
} else {
  alert("Cannot share file - try again on a different device")
}
}

text = 0
document.querySelectorAll('button').forEach(element => {
	mdc.ripple.MDCRipple.attachTo(document.querySelectorAll('button')[text]);
    text++
})

function gohome2() {
	document.getElementById("dashboard").style = "display: none;"
    document.getElementById("options").style = "display: block;"
}


function mainta(){
  document.getElementById("mainta").style.display = "block"
  document.getElementById("finalshloka").style = "display: none;"
  document.getElementById("shlokasting").style = "display: none;"
  document.getElementById("chapterstest").style = "display: none;"
  document.getElementById("extrasshow").style = "display: none;"
  document.getElementById("fullchapter").style = "display: none;"
  document.getElementById("read").style = "display: none;"
  document.getElementById("options").style = "display: none;"
  document.getElementById("finalshloka").style = "display: none;"
  document.getElementById("shlokasting").style = "display: none;"
  document.getElementById("chapterstest").style = "display: none;"
  document.getElementById("extrasshow").style = "display: none;"
  document.getElementById("fullchapter").style = "display: none;"
  document.getElementById("read").style = "display: none;"
  document.getElementById("options").style = "display: none;"
  document.getElementById("chapter").value = ""
  
}

function unmainta() {
document.getElementById("mainta").style.display = "none"
document.getElementById("finalshloka").style = "display: none;"
        	document.getElementById("shlokasting").style = "display: none;"
        	document.getElementById("chapterstest").style = "display: block;"
            document.getElementById("extrasshow").style = "display: none;"
        	document.getElementById("fullchapter").style = "display: none;"
        	document.getElementById("read").style = "display: none;"
            document.getElementById("options").style = "display: block;"
}


// Uncomment for maintainence:
// mainta()

  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());

  gtag('config', 'G-E6LF33ZH9Q');
