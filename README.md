# storage-market

You can find here the code for the article ["On the Efficiency of Energy Markets with Non-Merchant Storage"](https://link.springer.com/article/10.1007/s12667-024-00660-0). It runs with Julia v1.11.4 and the packages JuMP v1.11.4 (optimization), HiGHS v1.15.0 (solver), CSV v0.10.15, Plots v1.40.11, DataStructures v0.18.22, and DataFrames v1.7.0.

The models are available in the notebook **main_notebook.ipynb**, which contains the instructions for running it. It contains one section for clearing the whole horizon at once (ideal benchmark) and another section for clearing the market day by day.

The data for the generators, loads and storage can be modified in the csv files **data_gen.csv**, **data_load.csv** and **data_stg.csv**.

Finally, the folders [**Example Section III**](https://github.com/eleaprat/storage-market/tree/main/Example%20Section%20III) and [**Example Section IV**](https://github.com/eleaprat/storage-market/tree/main/Example%20Section%20IV) contain the csv files used in the illustrative examples of the paper.
