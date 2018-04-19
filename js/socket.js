// var socket = io('http://0.0.0.0:3000' Will not work on windows. Find a way to detect os and find localhost path in a settingsfile?

function myFunction(msg) {
    days = document.getElementById('days').value
    fed = document.getElementById('fed').value
    month = document.getElementById('month').value
    temp = document.getElementById('avg_sea_temp').value
    ls = {values: '[' + days + ',' + fed + ',' + month + ',' + temp + ']'}
    //console.log(ls)
    //console.log(days, fed, month, temp)
    $.post("http://127.0.0.1:8080/predict", ls, function( data ) {
      console.log(data)
      document.getElementById("answer").textContent = data.prediction[0];
    }); 
}

