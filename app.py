from flask import Flask, jsonify
from sklearn.externals import joblib
import numpy as np
import pandas as pd
from flask import request
#from flask_cors import CORS

app = Flask(__name__)
#CORS(app)

@app.route('/predict', methods=['POST'])
def predict():
	#Input values: [DAYS SINCE START, QTYFED, MONTH, AVG_SEA_TEMP_CUMULATIVE]
	#Outputs: AVERAGEWEIGHT
	json_ = request.form['values']
	values = np.array([[float(i) for i in json_[1:-1].split(',')]])
	prediction = model.predict(values)
	response = jsonify({'prediction': list(prediction)})
	response.headers.add('Access-Control-Allow-Origin', '*')
	return response

if __name__ == '__main__':
     model = joblib.load('model_params_1.pkl')
     app.run(port=8080)

