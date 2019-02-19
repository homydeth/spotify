
# coding: utf-8

import pandas as pd
import numpy as np
import requests
import cStringIO
import csv
import datetime
import json
import sys
reload(sys)
sys.setdefaultencoding('utf8')

pd.set_option('mode.chained_assignment',None)

import spotipy

client_id = 'YOUR_CLIENT_ID'
client_secret = 'YOUR_CLIENT_SECRET'

from spotipy.oauth2 import SpotifyClientCredentials

client_credentials_manager = SpotifyClientCredentials(client_id, client_secret)
sp = spotipy.Spotify(client_credentials_manager=client_credentials_manager)

start_date = datetime.date(2018,1,1)
end_date = datetime.date(2019,1,1)

streams = pd.DataFrame()

while start_date < end_date:
    url = 'https://spotifycharts.com/regional/global/daily/%s/download' % start_date.strftime('%Y-%m-%d')
    result = requests.get(url)
    if result.status_code == 200:
        fileobj = cStringIO.StringIO(result.text.encode('utf8', 'ignore'))

        try:
            df = pd.read_csv(fileobj, header=1)
        except Exception as e:
            pass

        df['date'] = start_date
        df['region'] = 'Global'
        df['track_id'] = df['URL'].str[-22:]
        streams = streams.append(df)
        start_date += datetime.timedelta(1)

    else:
        print result.status_code
        print result.text
        raise Exception('Response code not 200')

print start_date

print len(streams)

print streams.tail()

streams.to_csv('streams.csv', index=False)

#get an example of audio features
track_features = sp.audio_features('335SGs7Q58sUqkbgqF5Z3J')

#check the response format to find the fields we want
print track_features

tracks = streams['track_id'].unique()

print len(tracks)

features = pd.DataFrame(columns = ['track_id', 'energy', 'liveness', 'tempo', 'speechiness', 'acousticness'
                                   , 'instrumentalness', 'danceability', 'key', 'duration_ms', 'loudness'
                                   , 'mode', 'valence'])

fields = ['energy', 'liveness', 'tempo', 'speechiness', 'acousticness'
           , 'instrumentalness', 'danceability', 'key', 'duration_ms' ,'loudness', 'mode', 'valence']

for track in tracks:
    if track == None:
        pass
    else:
        audio_features = sp.audio_features(track)
        if audio_features[0] == None:
            pass
        else:
            row = [track] + [audio_features[0][k] for k in fields]
            features = features.append(pd.Series(data=row, index=features.columns.values), ignore_index=True)

features['mode'] = features['mode'].astype(int)

features['key'] = features['key'].astype(int)

print len(features)

print features.head()

features.to_csv('song_features.csv', index=False)

#get artist info
artists = streams['Artist'].unique()

print len(artists)

artists = artists[~pd.isnull(artists)]

artist_info = pd.DataFrame()

for name in artists:
    results = sp.search(q='artist:' + name, type='artist')
    #assume first search result is the artist we want
    if results['artists']['items'][0]['name'] == name:

        temp_df = {}
        temp_df['artist'] = results['artists']['items'][0]['name']
        temp_df['genres'] = results['artists']['items'][0]['genres']
        temp_df['popularity'] = results['artists']['items'][0]['popularity']
        temp_df['followers'] = results['artists']['items'][0]['followers']['total']
        temp_df['artist_id'] = results['artists']['items'][0]['uri'][-22:]

        artist_info = artist_info.append(temp_df, ignore_index=True)

artist_info['followers'] = artist_info['followers'].astype(int)
artist_info['popularity'] = artist_info['popularity'].astype(int)

print artist_info.tail()

artist_info.to_csv('artist_info.csv', index=False)




