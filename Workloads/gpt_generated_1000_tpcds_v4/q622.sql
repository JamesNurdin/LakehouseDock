WITH sales AS (
   SELECT d.d_year AS year,
          i.i_category AS category,
          CASE WHEN i.i_current_price > 100 THEN 'Expensive' ELSE 'Standard' END AS segment,
          'sales' AS metric,
          SUM(ss.ss_ext_sales_price) AS total_amount
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 1998 AND 2000
   GROUP BY d.d_year,
            i.i_category,
            CASE WHEN i.i_current_price > 100 THEN 'Expensive' ELSE 'Standard' END
),
returns AS (
   SELECT d.d_year AS year,
          i.i_category AS category,
          CASE WHEN sr.sr_return_amt > 50 THEN 'Large Return' ELSE 'Small Return' END AS segment,
          'returns' AS metric,
          SUM(sr.sr_return_amt) AS total_amount
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 1998 AND 2000
   GROUP BY d.d_year,
            i.i_category,
            CASE WHEN sr.sr_return_amt > 50 THEN 'Large Return' ELSE 'Small Return' END
)
SELECT *
FROM sales
UNION ALL
SELECT *
FROM returns
ORDER BY year, category, segment
LIMIT 100
