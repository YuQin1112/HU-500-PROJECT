# HU500

### We want to do the following steps
- [ ]	Clean up the raw data. There might be trash data that won’t contribute to the result
-	[ ] Process data and generate plots for the variables mentioned above
-	[ ] Use plot to find out if there any linear relationship between different variables
-	[ ] Derive modal TAXI_FARE = f(time, distance, passenger_number, location)
-	[ ] Back testing our modal

### The technique we plan to use
-	General statistic summary work, i.e. mean, mode, standard deviation, standard error
-	Analyze the correlation between time and passenger count (static location), location and passenger count(same time), time and location (not sure these two has any correlation but need analyze)
-	Linear Regression, lasso
-	Random Forest
-	Test with different model selection methods: forward selection, backward selection, stepwise selection, etc.
-	Break into training and testing datasets, and use different validation methods (k-fold, cross-validation, etc.)
### How will us evaluate results 
-	Compare with three main different methods: mean, linear regression and random forest.
-	Use root mean-squared error (RMSE) as the evaluation criteria to measure the prediction results 
-	Compare the model performance between training and testing datasets
-	Apply the final model to the testing data sets and see how well it’s predicting on the fares.
