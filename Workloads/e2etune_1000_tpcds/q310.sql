WITH combined_raw AS (
    SELECT d.d_year AS year,
           d.d_moy AS month,
           i.i_category AS category,
           cd.cd_gender AS gender,
           SUM(cs.cs_net_paid) AS sales_amount,
           0.0 AS return_amount,
           SUM(cs.cs_net_profit) AS profit_amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
      AND cd.cd_gender = 'M'
    GROUP BY d.d_year, d.d_moy, i.i_category, cd.cd_gender

    UNION ALL

    SELECT d.d_year AS year,
           d.d_moy AS month,
           i.i_category AS category,
           cd.cd_gender AS gender,
           0.0 AS sales_amount,
           SUM(sr.sr_return_amt) AS return_amount,
           0.0 AS profit_amount
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
      AND cd.cd_gender = 'M'
    GROUP BY d.d_year, d.d_moy, i.i_category, cd.cd_gender

    UNION ALL

    SELECT d.d_year AS year,
           d.d_moy AS month,
           i.i_category AS category,
           cd.cd_gender AS gender,
           0.0 AS sales_amount,
           SUM(wr.wr_return_amt) AS return_amount,
           0.0 AS profit_amount
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
      AND cd.cd_gender = 'M'
    GROUP BY d.d_year, d.d_moy, i.i_category, cd.cd_gender
),

agg AS (
    SELECT
        year,
        month,
        category,
        gender,
        SUM(sales_amount) AS total_sales,
        SUM(return_amount) AS total_returns,
        SUM(profit_amount) AS total_profit
    FROM combined_raw
    GROUP BY year, month, category, gender
),

ranked AS (
    SELECT
        year,
        month,
        category,
        gender,
        total_sales,
        total_returns,
        total_profit,
        (total_sales - total_returns) AS net_sales,
        ROW_NUMBER() OVER (PARTITION BY year, month ORDER BY (total_sales - total_returns) DESC) AS category_rank
    FROM agg
    WHERE (total_sales - total_returns) > 0
)

SELECT
    year,
    month,
    category,
    gender,
    total_sales,
    total_returns,
    total_profit,
    net_sales,
    category_rank
FROM ranked
ORDER BY year, month, category_rank
LIMIT 100
