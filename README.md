# Brazilian E-Commerce Sales Analysis

## Project overview

This portfolio project explores sales performance, product categories, delivery performance and geographic sales patterns using data from Olist, a Brazilian e-commerce marketplace.
The analysis uses five of the nine available tables: orders, order_items, products, customers and product category name translation table.

## Dataset

The dataset comes from the [Brazilian E-Commerce Public Dataset on Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce).
The selected tables contain 99,441 orders and related information about customers and products.
According to the dataset documentation, the commercial data is real and has been anonymised.
The dataset is published under the [CC BY-NC-SA 4.0 licence](https://creativecommons.org/licenses/by-nc-sa/4.0/).

## Methodology

I began by exploring the dataset in Excel to understand its structure, inspect data types and identify potential data quality issues. At this stage, I also selected five of the nine available tables for further analysis based on their relevance to the project's objectives.

I then used MySQL to investigate three main areas: customer behaviour, order and delivery performance and product sales. The SQL analysis included aggregations, customer-level metrics, delivery time calculations across successive delivery stages and product revenue rankings, with attention to product categories.

Finally, I prepared the data using Power Query, excluding city and ZIP code fields to focus the geographic analysis on state-level sales patterns. During data preparation, I standardised product category names by correcting inconsistencies in formatting and spelling, and completed missing English translations to ensure consistent category names across the report. I then built the data model, developed DAX measures and created interactive report pages in Power BI to present the findings.

## Key Findings

- **Sales and customers:** The dataset contains 99,441 orders placed between September 2016 and October 2018, associated with 96,096 unique customers
- **Product categories:** 74 product categories vary considerably in size, from just one product to 3,029 products in the largest category 
- **Leading category:** Health & Beauty generated approximately R$ 1.26 million in product revenue, making it the highest-revenue category
- **Revenue concentration:** In some categories, a small numer of products account for a substantial share of revenue. In Art, top 3 products generate 73.51% of category revenue.
- **Delivery performance:** 93.13% of orders were delivered within the estimated delivery time. However, the dataset does not provide enough information about how these estimations were calculated.
- **Geographic distribution:** Sao Paulo is the leading state by revenue, generating approximately R$ 5.2 million - 38.28% of total revenue
- **Revenue trends:** Monthly revenue increased substantially during 2017 before stabilising at around R$ 1 million per month. Analysis of Monthly Revenue combined with 3-month moving average suggests a decline towards the end of the analysed period.

## Tools & Technologies

- Microsoft Excel - initial data exploration
- MySQL - data exploration and analysis
- Power Query - data preparation
- Power BI - data modelling and dashboard development
- DAX - measures and analytical calculations