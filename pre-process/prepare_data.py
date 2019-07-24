import pandas
import sys
import time
from math import radians, cos, sin, asin, sqrt
from dateutil import parser
import pytz
from datetime import datetime, time
import os

CHUNK_SIZE = 10**5
OUTPUT = "real_data.csv"


def haversine(lon1, lat1, lon2, lat2):
    """
    this function takes two points of coordinates and return distance between them as mile.
    """

    # convert decimal degrees to radians 
    lon1, lat1, lon2, lat2 = map(radians, [lon1, lat1, lon2, lat2])
    
    # haversine formula 
    dlon = lon2 - lon1 
    dlat = lat2 - lat1 
    a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
    c = 2 * asin(sqrt(a)) 
    r = 3956  # Radius of earth in miles
    return c * r


def time_window(dt):
    """
    This function convert input ts into time window. 
    
    Time window defined as:
      - 1: 22:00 - 6:00. night and before morning
      - 2: 6:00 - 10:00. early summit of go to work
      - 3: 10:00 - 18:00. daytime
      - 4: 18:00 - 22:00. evening

    return timewindow number.
    """

    def _is_time_between(begin_time, end_time, check_time):

        if begin_time < end_time:
            return check_time >= begin_time and check_time <= end_time
        else: # crosses midnight
            return check_time >= begin_time or check_time <= end_time

    if _is_time_between(time(6,00), time(10,00), dt.time()):
        return 2
    elif _is_time_between(time(10,00), time(18,00), dt.time()):
        return 3
    elif _is_time_between(time(18,00), time(22,00), dt.time()):
        return 4
    else:
        return 1    

def update_dataframe(df_csv):

    for chunk in pandas.read_csv(df_csv, chunksize=CHUNK_SIZE):
        
        chunk_row_list = []

        for idx, row in chunk.iterrows():
            try:
                key, fare, pickup_ts, pickup_long, pickup_lat, dropoff_long, dropoff_lat, passenger_count = row
                dist = haversine(pickup_long, pickup_lat, dropoff_long, dropoff_lat)
                
                dt = parser.parse(pickup_ts)
                unix_dt = dt.timestamp()

                dtny = dt.astimezone(pytz.timezone('US/Eastern'))
                
                tw = time_window(dtny)
                weekday = dtny.weekday() + 1 # starts on 0

                new_row = {
                    'fare': fare, 'pickup_ts': unix_dt, 'pickup_long': pickup_long, 'pickup_lat': pickup_lat,
                    'dropoff_long': dropoff_long, 'dropoff_lat': dropoff_lat, 'passenger_count': passenger_count,
                    'time_window': tw, 'weekday': weekday, 'distance': dist
                }

                chunk_row_list.append(new_row)
            except:
                print(f"ERROR: mal-formed row:\n{row}")
                continue
        
        revised_chunk = pandas.DataFrame(chunk_row_list,
            columns=['fare', 'pickup_ts', 'pickup_long', 'pickup_lat',
                    'dropoff_long', 'dropoff_lat', 'passenger_count',
                    'time_window', 'weekday', 'distance']
        )

        with open(OUTPUT, "a") as f:
            revised_chunk.to_csv(f, header=False, mode='a', line_terminator="\n")

        # break here if in test mode, if you only want to see one chunk of data 


def main():
    df = sys.argv[1]
    update_dataframe(df)


if __name__ == "__main__":
    main()
