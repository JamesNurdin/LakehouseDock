WITH sales AS (
  SELECT cs.cs_sold_date_sk AS date_sk,
         cs.cs_promo_sk AS promo_sk,
         cs.cs_item_sk AS item_sk,
         cs.cs_ext_sales_price AS sales,
         cs.cs_quantity AS qty
  FROM catalog_sales cs
  UNION ALL
  SELECT ss.ss_sold_date_sk,
         ss.ss_promo_sk,
         ss.ss_item_sk,
         ss.ss_ext_sales_price,
         ss.ss_quantity
  FROM store_sales ss
  UNION ALL
  SELECT ws.ws_sold_date_sk,
         ws.ws_promo_sk,
         ws.ws_item_sk,
         ws.ws_ext_sales_price,
         ws.ws_quantity
  FROM web_sales ws
),
monthly AS (
  SELECT d.d_year,
         d.d_month_seq,
         i.i_category,
         sum(s.sales) AS monthly_sales,
         sum(s.qty) AS monthly_qty,
         count(DISTINCT p.p_promo_name) AS promo_count
  FROM sales s
  JOIN date_dim d ON s.date_sk = d.d_date_sk
  JOIN item i ON s.item_sk = i.i_item_sk
  LEFT JOIN promotion p ON s.promo_sk = p.p_promo_sk
  WHERE d.d_year BETWEEN 1998 AND 2002
  GROUP BY d.d_year, d.d_month_seq, i.i_category
)
SELECT d_year,
       d_month_seq,
       i_category,
       monthly_sales,
       monthly_qty,
       sum(monthly_sales) OVER (PARTITION BY d_year, i_category ORDER BY d_month_seq) AS cumulative_sales,
       sum(monthly_qty) OVER (PARTITION BY d_year, i_category ORDER BY d_month_seq) AS cumulative_qty,
       promo_count
FROM monthly
ORDER BY d_year, i_category, d_month_seq
