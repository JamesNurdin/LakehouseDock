WITH catalog_data AS (
    SELECT
        c.c_customer_id AS customer_id,
        d.d_year AS sales_year,
        CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Positive' ELSE 'Non-positive' END AS profit_flag,
        SUM(cs.cs_net_profit) AS total_net_profit,
        (SELECT AVG(cs2.cs_net_profit)
         FROM catalog_sales cs2
         JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
         WHERE d2.d_year = d.d_year) AS avg_year_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND hd.hd_income_band_sk >= 8
      AND NOT EXISTS (
          SELECT 1
          FROM store_sales ss
          WHERE ss.ss_customer_sk = c.c_customer_sk
            AND ss.ss_sold_date_sk = d.d_date_sk
      )
    GROUP BY c.c_customer_id, d.d_year
),
store_data AS (
    SELECT
        c.c_customer_id AS customer_id,
        d.d_year AS sales_year,
        CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'Positive' ELSE 'Non-positive' END AS profit_flag,
        SUM(ss.ss_net_profit) AS total_net_profit,
        (SELECT AVG(ss2.ss_net_profit)
         FROM store_sales ss2
         JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
         WHERE d2.d_year = d.d_year) AS avg_year_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND hd.hd_income_band_sk <= 5
      AND NOT EXISTS (
          SELECT 1
          FROM catalog_sales cs
          WHERE cs.cs_bill_customer_sk = c.c_customer_sk
            AND cs.cs_sold_date_sk = d.d_date_sk
      )
    GROUP BY c.c_customer_id, d.d_year
)
SELECT
    customer_id,
    sales_year,
    profit_flag,
    total_net_profit,
    avg_year_profit
FROM catalog_data
UNION ALL
SELECT
    customer_id,
    sales_year,
    profit_flag,
    total_net_profit,
    avg_year_profit
FROM store_data
ORDER BY total_net_profit DESC
LIMIT 100
