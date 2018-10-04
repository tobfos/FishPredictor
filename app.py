from flask import Flask, jsonify
from sklearn.externals import joblib
import numpy as np
import pandas as pd
from flask import request
from scipy.spatial.distance import cdist


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


title_list = ['Mr', 'Miss', 'Mrs', 'Dr']


def my_title_func(title):
    if (title in title_list):
        return title
    else:
        return 'Annet'


def sex_to_number(sex):
    if sex.lower() == 'mann' or sex.lower() == 'male':
        return 0
    if sex.lower() == 'kvinne' or sex.lower() == 'female':
        return 1


def get_family_size(df):
    df["family_size"] = df.sibsp + df.parch + 1
    return df


def create_alone(df):
    df["isAlone"] = [1 for i in range(df.shape[0])]
    df["isAlone"][df.family_size > 1] = [
        0 for i in range(df.isAlone[df.family_size > 1].shape[0])]
    return df


def process_dataset():
    df = pd.read_excel('titanic.xls')
    temp = df.name.apply(lambda x: x.split(',')[1].split('.')[0].strip())
    df['title'] = temp.apply(my_title_func)
    df = df.loc[[not i for i in df.age.isna()], :]
    df = df.pipe(get_family_size).pipe(create_alone)
    df["sex"] = df["sex"].apply(lambda x: sex_to_number(x))
    df["title"] = df["title"].apply(lambda x: title_to_number(x))
    df_org = df.copy()
    df = df.drop(['survived', "home.dest", "body", "boat", "cabin",
                 "ticket", "fare", "name", "sibsp", "parch", "embarked"], axis=1)
    return df, df_org


def get_closest_persons(observation, n_persons=1):
    return df_org.iloc[np.argsort(cdist(np.array([observation]), df))[0][:n_persons]]


app = Flask(__name__)


@app.route('/predict', methods=['POST'])
def predict():
	# parameters in form: class, sex, age, title, familySize
	# Outputs: 0 - ded, 1 - survived
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
    closest_person = get_closest_persons([class_, sex, age, title, familySize, isAlone], n_persons=2)

    #['sibsp', 'parch', 'home.dest'] 
    response = jsonify({
        'survivalScore': str(prediction),
        'mostSimilarPerson': {
            'name': str(closest_person['name'].values[0]),
            'sex': str(closest_person['sex'].values[0]),
            'age': str(closest_person['age'].values[0]),
            'class': str(closest_person['pclass'].values[0]),
            'fare price': str(closest_person['fare'].values[0]),
            'home destination': str(closest_person['home.dest'].values[0]),
            '# of parents / children aboard the Titanic': str(closest_person['parch'].values[0]),
            '# of siblings / spouses aboard the Titanic': str(closest_person['sibsp'].values[0]),
            'survived': str(closest_person['survived'].values[0]),
            },
        'secondMostSimilarPerson': {
            'name': str(closest_person['name'].values[1]),
            'sex': str(closest_person['sex'].values[1]),
            'age': str(closest_person['age'].values[1]),
            'class': str(closest_person['pclass'].values[1]),
            'fare price': str(closest_person['fare'].values[1]),
            'home destination': str(closest_person['home.dest'].values[1]),
            '# of parents / children aboard the Titanic': str(closest_person['parch'].values[1]),
            '# of siblings / spouses aboard the Titanic': str(closest_person['sibsp'].values[1]),
            'survived': str(closest_person['survived'].values[1]),
            },
        })
    response.headers.add('Access-Control-Allow-Origin', '*')
    return response

if __name__ == '__main__':
     df, df_org = process_dataset()
     model = joblib.load('randomForest_1.joblib')
     app.run(port=8080)

