# ------------------------------------
# 0) Setup — Package Install & Import
# ------------------------------------

#install.packages("caret")
#install.packages("rpart")
#install.packages("rpart.plot")
#install.packages("e1071")
#install.packages("randomForest")
#install.packages("arules")

library(caret)
library(rpart)
library(rpart.plot)
library(e1071)
library(randomForest)
library(arules)
library(tidyselect)

set.seed(1)

# -----------------------------
# 1) Load dataset
# -----------------------------

zooData <- read.csv(file = "/Users/themi/Downloads/zoo.csv")

cat("Rows:", nrow(zooData), "| Cols:", ncol(zooData), "\n\n")
print(head(zooData))
cat("\nStructure (before cleaning):\n")
str(zooData)

# -----------------------------
# 2) Preprocessing for classification
# -----------------------------
# Remove 'animal' (unique)
if ("animal" %in% names(zooData)) {
  zooData <- subset(zooData, select = -animal)
}

# Convert character true/false columns to logical
char_columns <- sapply(zooData, is.character)

# 'type' is the label column (should remain categorical), not logical conversion
if ("type" %in% names(char_columns)) {
  char_columns["type"] <- FALSE
}

# Convert all remaining character columns ("true"/"false") -> logical
if (any(char_columns)) {
  zooData[char_columns] <- lapply(zooData[char_columns], function(x) tolower(x) == "true")
}

# Convert target label to factor
if (!("type" %in% names(zooData))) stop("Column 'type' not found in zoo dataset.")
zooData$type <- as.factor(zooData$type)

cat("\nStructure (after cleaning):\n")
str(zooData)

# Quick sanity checks
cat("\nNA check by column:\n")
print(colSums(is.na(zooData)))

cat("\nClass distribution (type):\n")
print(table(zooData$type))

# -----------------------------
# 3) Stratified train/test split (70/30)
# -----------------------------
trainingIndex <- createDataPartition(zooData$type, p = 0.70, list = FALSE)

trainingData <- zooData[trainingIndex, ]
testingData  <- zooData[-trainingIndex, ]

cat("\nTrain rows:", nrow(trainingData), "| Test rows:", nrow(testingData), "\n")

# -----------------------------
# 4) Decision Tree (rpart)
# -----------------------------
decision_tree_model <- rpart(type ~ ., data = trainingData, method = "class")

cat("\nDecision Tree CP table:\n")
printcp(decision_tree_model)

rpart.plot(decision_tree_model)

decision_tree_pred <- predict(decision_tree_model, testingData, type = "class")
decision_tree_cm <- confusionMatrix(decision_tree_pred, testingData$type)

cat("\nDecision Tree Confusion Matrix:\n")
print(decision_tree_cm)

decision_tree_accuracy <- sum(diag(decision_tree_cm$table)) / sum(decision_tree_cm$table)

# -----------------------------
# 5) Naive Bayes (e1071)
# -----------------------------
naive_bayes_model <- naiveBayes(type ~ ., data = trainingData)
naive_bayes_pred <- predict(naive_bayes_model, testingData)

naive_bayes_cm <- confusionMatrix(naive_bayes_pred, testingData$type)

cat("\nNaive Bayes Confusion Matrix:\n")
print(naive_bayes_cm)

naive_bayes_accuracy <- sum(diag(naive_bayes_cm$table)) / sum(naive_bayes_cm$table)

# -----------------------------
# 6) Random Forest (200 trees)
# -----------------------------
random_forest_model <- randomForest(type ~ ., data = trainingData, ntree = 200)

random_forest_pred <- predict(random_forest_model, testingData)

random_forest_cm <- confusionMatrix(random_forest_pred, testingData$type)

cat("\nRandom Forest Confusion Matrix:\n")
print(random_forest_cm)

random_forest_accuracy <- sum(diag(random_forest_cm$table)) / sum(random_forest_cm$table)

# -----------------------------
# 7) Classification comparison table
# -----------------------------
comparison_table_classification <- data.frame(
  Model = c("Decision Tree", "Naive Bayes", "Random Forest"),
  Accuracy = c(decision_tree_accuracy, naive_bayes_accuracy, random_forest_accuracy),
  Kappa = c(
    as.numeric(decision_tree_cm$overall["Kappa"]),
    as.numeric(naive_bayes_cm$overall["Kappa"]),
    as.numeric(random_forest_cm$overall["Kappa"])
  ),
  CI_Lower = c(
    as.numeric(decision_tree_cm$overall["AccuracyLower"]),
    as.numeric(naive_bayes_cm$overall["AccuracyLower"]),
    as.numeric(random_forest_cm$overall["AccuracyLower"])
  ),
  CI_Upper = c(
    as.numeric(decision_tree_cm$overall["AccuracyUpper"]),
    as.numeric(naive_bayes_cm$overall["AccuracyUpper"]),
    as.numeric(random_forest_cm$overall["AccuracyUpper"])
  )
)

cat("\nClassification Comparison:\n")
print(comparison_table_classification)

# -----------------------------
# 8) Apriori
# -----------------------------

library(arules)

zooDataApriori <- zooData

# Drop supervised label + numeric legs
drop_cols <- intersect(c("type", "legs"), names(zooDataApriori))
if (length(drop_cols) > 0) {
  zooDataApriori <- zooDataApriori[, !(names(zooDataApriori) %in% drop_cols), drop = FALSE]
}
# If any remaining columns are character ("true"/"false"), convert to logical
char_cols <- sapply(zooDataApriori, is.character)
if (any(char_cols)) {
  zooDataApriori[char_cols] <- lapply(zooDataApriori[char_cols], function(x) tolower(x) == "true")
}

# Convert logical columns to factors with explicit levels so arules treats them as categorical items
log_cols <- sapply(zooDataApriori, is.logical)
if (any(log_cols)) {
  zooDataApriori[log_cols] <- lapply(zooDataApriori[log_cols], function(x) {
    factor(x, levels = c(FALSE, TRUE), labels = c("no", "yes"))
  })
}

# If there are any numeric columns left (shouldn't be, but just in case), drop them for clean item mining
num_cols <- sapply(zooDataApriori, is.numeric)
if (any(num_cols)) {
  warning("Dropping unexpected numeric columns for Apriori: ",
          paste(names(zooDataApriori)[num_cols], collapse = ", "))
  zooDataApriori <- zooDataApriori[, !num_cols, drop = FALSE]
}

# Convert to transactions
zoo_transactions <- as(zooDataApriori, "transactions")

cat("\nApriori Transactions Summary:\n")
print(summary(zoo_transactions))

# Helper to inspect top 10 by lift
inspect_top10_lift <- function(rules_obj) {
  if (length(rules_obj) == 0) {
    cat("No rules generated under these thresholds.\n")
    return(invisible(NULL))
  }
  rules_sorted <- sort(rules_obj, by = "lift", decreasing = TRUE)
  inspect(rules_sorted[seq_len(min(10, length(rules_sorted)))])
}

# Run 1: supp 30%, conf 60%
rules_1 <- apriori(zoo_transactions, parameter = list(supp = 0.30, conf = 0.60))
cat("\nApriori Run 1 (supp=0.30, conf=0.60) - Top 10 by lift:\n")
inspect_top10_lift(rules_1)

# Run 2: supp 50%, conf 80%
rules_2 <- apriori(zoo_transactions, parameter = list(supp = 0.50, conf = 0.80))
cat("\nApriori Run 2 (supp=0.50, conf=0.80) - Top 10 by lift:\n")
inspect_top10_lift(rules_2)

# Run 3: supp 10%, conf 70%
rules_3 <- apriori(zoo_transactions, parameter = list(supp = 0.10, conf = 0.70))
cat("\nApriori Run 3 (supp=0.10, conf=0.70) - Top 10 by lift:\n")
inspect_top10_lift(rules_3)

# -----------------------------
# 9) Save cleaned data + outputs (portfolio-grade)
# -----------------------------
out_dir <- file.path("data", "processed")
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

# Save cleaned classification dataset (after removing animal + converting types)
write.csv(zooData, file.path(out_dir, "zoo_cleaned_for_classification.csv"), row.names = FALSE)

# Save classification comparison metrics
write.csv(comparison_table_classification,
          file.path(out_dir, "classification_model_comparison.csv"),
          row.names = FALSE)

# Save Apriori transaction-ready dataset (TRUE -> feature name, FALSE -> NA)
write.csv(zooDataApriori, file.path(out_dir, "zoo_prepared_for_apriori.csv"), row.names = FALSE)

# Save Apriori rules from run 1 (supp=0.30, conf=0.60)
write.csv(as(rules_1, "data.frame"),
          file.path(out_dir, "apriori_rules_run1_supp0.30_conf0.60.csv"),
          row.names = FALSE)

# Save Apriori rules from run 2 (supp=0.50, conf=0.80)
write.csv(as(rules_2, "data.frame"),
          file.path(out_dir, "apriori_rules_run2_supp0.50_conf0.80.csv"),
          row.names = FALSE)

# Save Apriori rules from run 3 (supp=0.10, conf=0.70)
write.csv(as(rules_3, "data.frame"),
          file.path(out_dir, "apriori_rules_run3_supp0.10_conf0.70.csv"),
          row.names = FALSE)

