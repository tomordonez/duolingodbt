# Duolingo Spaced-Repetition Learning Data Warehouse

## References

B. Settles, "Replication Data for: A Trainable Spaced Repetition Model for Language Learning," Harvard Dataverse, V1, 2017. [Online]. Available: https://doi.org/10.7910/DVN/N8XJME

## Data Ingestion

Load the raw CSV dataset into BigQuery:

* Created a bucket in Cloud Storage (cheapest option)
* Uploaded csv.gz file
* Created a dataset in BigQuery (cheapest options)
* In the dataset, created a table and selected from the bucket, type CSV, native table, detect schema, etc

Current schema

p_recall: FLOAT
timestamp: INTEGER
delta: INTEGER
user_id: STRING
learning_language: STRING
ui_language: STRING
lexeme_id: STRING
history_seen: INTEGER
history_correct: INTEGER
session_seen: INTEGER
session_correct: INTEGER

## Staging

### Raw Dataset

**Rename columns**

    ui_language as native_language
    p_recall as probability_recall_word
    delta as lag_seconds_since_last_practice
    history_seen as total_times_seen_word
    history_correct as total_times_correct_word
    session_seen as session_times_seen_word
    session_correct as session_times_correct_word

**Create columns**

    user_id || lexeme_id || delta as trace_id
    ui_language || '-' || learning_language as language_pair_code
    delta / 3600 as lag_hours_since_last_practice
    delta / 86400 as lag_days_since_last_practice

**Create features**

Other columns that can be used as features in the neural net model.

    (history_correct / NULLIF(history_seen, 0)) as history_learning_rate
    (session_correct / NULLIF(session_seen, 0)) as session_learning_rate

Measure how familiar a user is with a lexeme. Number of times a lexeme has been seen historically

    LOG(1 + history_seen) as lexeme_familiarity

Time effectiveness combined with recall rate

    (p_recall / NULLIF(LOG(1 + delta), 0)) as time_effectiveness_since_last_practice

Probability of remembering a lexeme decreases over time since last practice

    EXP(-delta / 86400) as time_decay_factor

Measure change in probability recall between current record and next one adjusted by time interval since last practice normalized to hours.

    (LEAD(p_recall, 1) OVER (PARTITION BY user_id, lexeme_id ORDER BY timestamp_seconds(`timestamp`)) - p_recall) 
    / GREATEST(delta / 3600, 1) as forgetting_rate

Timestamps

    timestamp_seconds(`timestamp`) as created_at
    DATE(timestamp_seconds(`timestamp`)) as created_date
    TIME(timestamp_seconds(`timestamp`)) as created_time

**Filter native language**

    where native_language = 'en'

### Seeds

A seed `languages.csv` with this schema

    language_code,language_name,is_germanic,is_romance

### Utilities

**Date Dimension**

* Added the package `calogica/dbt_date`
* Created the model `dim_date.sql`

## Intermediate

* Joined the staging dataset with the native language seed and the date dimension
* The result is ~7 Million rows

## Marts / Analytics

Created aggregation models with normalized features that use Z-score and Min-Max.

**Standardization**

Z-score (standardization, scikit `StandardScaler`), rescales the features to standard normal distribution with `mean = 0` and `std = 1`

    z = (x - mean) / std

It uses this SQL example, where `OVER()` is used without window frame to get the average over all rows:

    (raw_session_learning_rate - AVG(raw_session_learning_rate) OVER()) / STDDEV(raw_session_learning_rate) OVER() AS standardized_session_learning_rate

Min-max (scikit `MinMaxScaler`) rescales the values to a range from 0 to 1

    x' = (x - min(x)) / (max(x) - min(x))

It uses this SQL example:

    (standardized_session_learning_rate - MIN(standardized_session_learning_rate) OVER()) / (MAX(standardized_session_learning_rate) OVER() - MIN(standardized_session_learning_rate) OVER()) AS session_learning_rate

**Models**

Created aggregation models to analyze if a native English speaker learns another Germanic language (e.g., English, German) faster than a Romance language (Spanish, Italian, Portuguese, French)

## Rules-based model

Using Google Colab, connected to the intermediate model in BigQuery to load the dataset using pandas. Used scikit-learn to apply the same standardization to the features (I couldn't apply them in the intermediate model in BigQuery because the resource I used was the cheapest and when trying to run this transformation, the resource reached the memory limits).

Installed the package `durable-rules` to create a model that outputs spaced-repetition learning schedules.

## Neural Net model

With the dataset in a pandas dataframe, already standardized, used PyTorch to create a neural net model that also outputs spaced-repetition learning schedules.