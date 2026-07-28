/*
  Goal: Identify top-selling item categories per year where the item description contains a four‑digit year pattern, 
  filter on promotions that are not TV‑channel, compute various sales metrics, include a scalar subquery for average 
  promotion cost per item, apply string functions (regexp_like, regexp_extract, LIKE, CONCAT), and add window functions
  for running category sales and ranking. Return the first 100 rows.
*/
WITH daily_sales AS (
   SELECT
       d.d_year,
       i.i_category,
       i.i_item_sk,
       ws.ws_ext_sales_price,
       ws.ws_ext_discount_amt,
       i.i_product_name,
       regexp_extract(i.i_item_desc, '(\\d{4})') AS desc_year
   FROM web_sales ws
   JOIN date_dim d        ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i           ON ws.ws_item_sk = i.i_item_sk
   JOIN promotion p      ON ws.ws_promo_sk = p.p_promo_sk
   WHERE regexp_like(i.i_item_desc, '[A-Za-z]+\\s\\d{4}')
     AND p.p_channel_tv = 'N'
),
agg_sales AS (
   SELECT
       d_year,
       i_category,
       CASE WHEN i_product_name LIKE '%Deluxe%' THEN 'Deluxe' ELSE 'Other' END AS product_type,
       i_item_sk,
       sum(ws_ext_sales_price) AS total_sales,
       count(*)               AS sales_cnt,
       avg(ws_ext_discount_amt) AS avg_discount
   FROM daily_sales
   GROUP BY d_year, i_category, i_product_name, i_item_sk
)
SELECT
    a.d_year,
    a.i_category,
    a.product_type,
    a.total_sales,
    a.sales_cnt,
    a.avg_discount,
    (SELECT avg(p2.p_cost)
       FROM promotion p2
       WHERE p2.p_item_sk = a.i_item_sk) AS avg_item_promo_cost,
    sum(a.total_sales) OVER (
        PARTITION BY a.i_category
        ORDER BY a.d_year
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_cat_sales,
    row_number() OVER (
        PARTITION BY a.i_category
        ORDER BY a.total_sales DESC) AS sales_rank,
    concat('Cat_', a.i_category) AS category_label
FROM agg_sales a
WHERE regexp_like(a.i_category, '^\\w+$')
ORDER BY a.total_sales DESC
LIMIT 100
