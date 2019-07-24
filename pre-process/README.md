### Pre process training data

This is a python program since the training data is too big.
R trims the data when load. we are not yet find a good solution on it.

This program factor original training data into new data frame.

### New data frame

|column name|type|description|
|--|--|--|
|fare|float|money paid on this ride|
|pickup_ts|int|unix timestamp of the pickup time|
|pickup_long|float|pickup longtitude|
|pickup_lat|float|pickup latitude|
|dropoff_long|float|dropoff longtitude|
|dropoff_lat|float|dropoff lattitude|
|passenger_count|int|number of passenger|
|time_window|int|time in range of 4 partitions in a day|
|weekday|int|Monday to Sunday as number 1 to 7|
|distance|float|distance in mile between pickup and fropoff|

More info for `time window`:

```
    Time window defined as:
      - 1: 22:00 - 6:00. night and before morning
      - 2: 6:00 - 10:00. early summit of go to work
      - 3: 10:00 - 18:00. daytime
      - 4: 18:00 - 22:00. evening
```

### Fail over

If there are some rows mal-formed, program will print error log and skip process this row.

### Usage

`python prepare_data.py /path/to/train.csv`

after program finish, a `real_data.csv` will be generated under your current directory.