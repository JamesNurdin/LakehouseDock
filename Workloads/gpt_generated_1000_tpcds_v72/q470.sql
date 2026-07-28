WITH sales_metrics AS (
   SELECT
       d.d_year,
       d.d_month_seq,
       'catalog_sales' AS source,
       SUM(cs.cs_net_profit) AS total_amount
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   WHERE regexp_like(i.i_item_desc, '(?i)steel')
     AND p.p_promo_name LIKE '%Discount%'
   GROUP BY d.d_year, d.d_month_seq
),
return_metrics AS (
   SELECT
       d.d_year,
       d.d_month_seq,
       'store_returns' AS source,
       SUM(sr.sr_return_amt) AS total_amount
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   WHERE regexp_extract(i.i_item_desc, '(?i)\\b(PROMO)\\b', 1) = 'PROMO'
     AND substr(i.i_item_id, 1, 3) = '100'
   GROUP BY d.d_year, d.d_month_seq
)
SELECT *
FROM sales_metrics
UNION ALL
SELECT *
FROM return_metrics
ORDER BY d_year, d_month_seq, source, total_amount DESC
LIMIT 100
