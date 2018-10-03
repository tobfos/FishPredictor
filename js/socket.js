// var socket = io('http://0.0.0.0:3000' Will not work on windows. Find a way to detect os and find localhost path in a settingsfile?

function myFunction() {
  class_ = document.getElementById('class').value
  sex = document.getElementById('sex').value
  age = document.getElementById('age').value
  title = document.getElementById('title').value
  familySize = document.getElementById('familySize').value

 var form = {}
 form["class"] = class_;
 form["sex"] = sex;
 form["age"] = age;
 form["title"] = title;
 form["familySize"] = familySize;
      $.post("http://127.0.0.1:8080/predict", form, function( data ) {
        console.log(data)
        document.getElementById("answer").textContent = data.survivalScore;
      }); 
}