WITH sales_agg AS (
  SELECT
    i.i_category AS category,
    'sales' AS src,
    SUM(cs.cs_ext_sales_price) AS amount,
    COUNT(DISTINCT cs.cs_order_number) AS orders
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  WHERE td.t_hour BETWEEN 8 AND 18
    AND cd.cd_marital_status = 'M'
  GROUP BY i.i_category
),
returns_agg AS (
  SELECT
    i.i_category AS category,
    'returns' AS src,
    SUM(wr.wr_return_amt) AS amount,
    COUNT(*) AS orders
  FROM web_returns wr
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
  JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
  WHERE td.t_hour BETWEEN 8 AND 18
    AND cd.cd_marital_status = 'M'
  GROUP BY i.i_category
)
SELECT *
FROM sales_agg
UNION ALL
SELECT *
FROM returns_agg
ORDER BY amount DESC
LIMIT 100
