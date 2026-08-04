WITH latest_year AS (
  SELECT MAX(d_year) AS max_year
  FROM date_dim
),
sales AS (
  SELECT cs.cs_order_number,
         cs.cs_net_profit,
         cs.cs_ext_sales_price,
         i.i_item_sk,
         i.i_product_name,
         p.p_promo_sk,
         p.p_promo_name,
         d.d_year,
         CASE WHEN cs.cs_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE regexp_like(i.i_product_name, '^[A-Z]{3,}')
    AND p.p_promo_name LIKE '%Clearance%'
    AND d.d_year = (SELECT max_year FROM latest_year)
),
sales_with_word AS (
  SELECT s.*, 
         lw.first_word,
         concat(lw.first_word, '-PROMO') AS promo_key
  FROM sales s
  LEFT JOIN LATERAL (
    SELECT regexp_extract(s.i_product_name, '^([^ ]+)', 1) AS first_word
  ) lw ON TRUE
),
return_orders AS (
  SELECT cr.cr_order_number
  FROM catalog_returns cr
  WHERE cr.cr_return_amount > 0
),
sale_orders AS (
  SELECT cs.cs_order_number
  FROM catalog_sales cs
  WHERE cs.cs_net_paid > 0
),
common_orders AS (
  SELECT cs_order_number FROM sale_orders
  INTERSECT
  SELECT cr_order_number FROM return_orders
)
SELECT sw.first_word,
       sw.p_promo_name,
       SUM(sw.cs_net_profit) AS total_net_profit,
       COUNT(DISTINCT sw.cs_order_number) AS orders_count,
       MAX(sw.cs_ext_sales_price) AS max_ext_sales,
       sw.promo_key
FROM sales_with_word sw
JOIN common_orders co ON sw.cs_order_number = co.cs_order_number
GROUP BY sw.first_word, sw.p_promo_name, sw.promo_key
HAVING SUM(sw.cs_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 100
