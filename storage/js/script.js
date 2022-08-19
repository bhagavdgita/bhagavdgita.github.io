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
	
    
    extras = ["dhyana"]
    
    
    if (extras.includes(document.getElementById("chapter").value)) {
    
    
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
        document.getElementById("theshlokas").innerHTML = result
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
        	document.getElementById("fullchapter").style = "display: none;"
        	document.getElementById("read").style = "display: none;"
            document.getElementById("options").style = "display: block;"
        } else {
        	document.getElementById("finalshloka").style = "display: none;"
        	document.getElementById("shlokasting").style = "display: none;"
        	document.getElementById("chapterstest").style = "display: block;"
        	document.getElementById("fullchapter").style = "display: none;"
        	document.getElementById("read").style = "display: block;"
            document.getElementById("options").style = "display: none;"
            document.getElementById("chapter").value = ""
            showbackpage = "options"
        }
}

mdc.ripple.MDCRipple.attachTo(document.querySelector('button'));
mdc.ripple.MDCRipple.attachTo(document.querySelector('.mdc-fab'));
