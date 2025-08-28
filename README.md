# :clipboard: Power BI on Databricks SQL - QuickStarts :rocket:


## Introduction

This repo contains the quickstarts demonstrating the usage of [Power BI](https://powerbi.microsoft.com/) on [Databricks SQL](https://www.databricks.com/product/databricks-sql). The objective of these quickstarts is to demonstrate reference implementation and some of the best practices using Power BI on Databricks SQL.

For quick access to [this repository](./) and [Best Practices Cheat Sheet](https://www.databricks.com/sites/default/files/2025-04/2025-04-power-bi-on-databricks-best-practices-cheat-sheet.pdf) please use the QR-code below. 👇


| QuickStart Samples repo | Best Practices Cheat Sheet |
| ------ | ----------- |
| <p align="center"> <img width="35%" src="./images/qrcode-repo.png" /> </p> | <p align="center"> <img width="30%" src="./images/qrcode-cheatsheet.png" /> </p> |



## Table of Contents

| #    | Folder | Description |
| ---- | ------ | ----------- |
| 00   | [Best Practices Cheat Sheet](00.%20Best%20Practices%20Cheat%20Sheet/)    | Power BI on Databricks Best Practices Cheat Sheet    |
| 01   | [Connection Parameters](01.%20Connection%20Parameters/)    | Use Power BI parameters to efficiently manage connections to Databricks SQL    |
| 02   | [Storage Modes](./02.%20Storage%20Modes/)    | Use storage modes efficiently - DirectQuery vs Dual vs Import    |
| 03   | [Logical Partitioning](./03.%20Logical%20Partitioning/)    | Improving data refresh performance with Power BI partitioning    |
| 04   | [Query Parallelization](./04.%20Query%20Parallelization/)    | Improve Power BI DirectQuery performance by tuning query parallelization    |
| 05   | [User-defined Aggregations](./05.%20User-defined%20Aggregations/)    | Improve Power BI DirectQuery performance by using User-defined aggregations    |
| 06   | [Dynamic M Query Parameters](./06.%20Dynamic%20M%20Query%20Parameters/)    |  Use Dynamic M Query Parameters for better control over SQL-query generation and performance optimization   |
| 07   | [Query optimization using PK](./07.%20Query%20optimization%20using%20PK/)    |  Query optimization using primary key constraints   |
| 08   | [Automatic aggregations](./08.%20Automatic%20aggregations/)    |  Improve Power BI DirectQuery performance by using Automatic aggregations   |
| 09   | [Private Connections](./09.%20Private%20Connections/)    |  Private connections to Databricks Workspaces from Power BI Service   |
| 10   | [Pushdown Calculations](10.%20Pushdown%20Calculations/)    |  Improve Power BI DirectQuery performance by pushing calculations down to Databricks SQL  |
| 11   | [Generated vs Persisted dimensions](./11.%20Generated%20vs%20Persisted%20dimension/)    |  Improve Power BI DirectQuery performance by using generated vs persisted dimension tables  |
| 12   | [Collations](./12.%20Collations/)    |  Use Collations for case-insensitive search and filtering  |
| 13   | [M2M OAuth Credentials Management](./13.%20M2M%20OAuth%20Credentials%20Management/)    |  Use M2M OAuth authentication for non-interactive workloads  |


## How to get help

Databricks support doesn't cover this content. For questions or bugs, please open a GitHub issue and the team will help on a best effort basis.


## License

&copy; 2025 Databricks, Inc. All rights reserved. The source code in this repository is provided subject to the [Databricks License](https://databricks.com/db-license-source).  All included or referenced third party libraries are subject to the licenses set forth below.


| library                                | description.               | license    | source                                                            |
|----------------------------------------|----------------------------|------------|-------------------------------------------------------------------|
| PowerBI-Developer-Samples              | Power BI Developer Samples | MIT        | [Github](https://github.com/microsoft/PowerBI-Developer-Samples/) |