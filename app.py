from flask import Flask, jsonify
from sklearn.externals import joblib
import numpy as np
import pandas as pd
from flask import request
#from flask_cors import CORS
def title_to_number(title):
    title = title.lower()
    if title == 'mr':
        return 0
    elif title == 'miss':
        return 1
    elif title == 'mrs':
        return 2
    elif title == 'dr':
        return 3
    elif title == 'annet':
        return 4

def sex_to_number(sex):
    if sex.lower() == 'mann':
        return 0
    if sex.lower() == 'kvinne':
        return 1

app = Flask(__name__)

@app.route('/predict', methods=['POST'])
def predict():
	#parameters in form: class, sex, age, title, familySize
	#Outputs: 0 - ded, 1 - survived
	class_ = int(request.form['class'])

	sex = request.form['sex']
	sex = sex_to_number(sex)
	
	age = float(request.form['age'])

	title = request.form['title']
	title = title_to_number(title)

	familySize = 1 + float(request.form['familySize'])

	isAlone = 0
	if familySize == 1:
		isAlone = 1

	prediction = model.predict_proba([[class_, sex, age, title, familySize, isAlone]])[0][1]
	response = jsonify({'survivalScore': str(prediction)})
	response.headers.add('Access-Control-Allow-Origin', '*')
	return response

if __name__ == '__main__':
     model = joblib.load('randomForest_1.joblib')
     app.run(port=8080)

