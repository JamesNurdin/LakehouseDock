WITH sales AS (
  SELECT ss_sold_date_sk AS date_sk,
         ss_item_sk AS item_sk,
         ss_net_paid AS net_paid
  FROM store_sales
  UNION ALL
  SELECT ws_sold_date_sk AS date_sk,
         ws_item_sk AS item_sk,
         ws_net_paid AS net_paid
  FROM web_sales
  UNION ALL
  SELECT cs_sold_date_sk AS date_sk,
         cs_item_sk AS item_sk,
         cs_net_paid AS net_paid
  FROM catalog_sales
),
agg AS (
  SELECT d.d_year,
         i.i_category,
         SUM(s.net_paid) AS total_sales
  FROM sales s
  JOIN date_dim d ON s.date_sk = d.d_date_sk
  JOIN item i ON s.item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
  GROUP BY d.d_year, i.i_category
)
SELECT d_year,
       i_category,
       total_sales,
       RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
FROM agg
ORDER BY d_year, total_sales DESC
