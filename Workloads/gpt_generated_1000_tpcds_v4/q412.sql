WITH inventory_agg AS (
  SELECT inv_item_sk,
         SUM(inv_quantity_on_hand) AS total_on_hand
  FROM inventory
  GROUP BY inv_item_sk
),
sales_agg AS (
  SELECT
    ss.ss_item_sk AS item_sk,
    ss.ss_store_sk AS store_sk,
    ss.ss_promo_sk AS promo_sk,
    SUM(ss.ss_ext_sales_price) AS amount,
    SUM(ss.ss_quantity) AS units,
    'sale' AS src
  FROM store_sales ss
  WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2451179
    AND ss.ss_quantity > 0
  GROUP BY ss.ss_item_sk, ss.ss_store_sk, ss.ss_promo_sk
),
returns_agg AS (
  SELECT
    wr.wr_item_sk AS item_sk,
    CAST(NULL AS INTEGER) AS store_sk,
    p.p_promo_sk AS promo_sk,
    SUM(wr.wr_return_amt) AS amount,
    SUM(wr.wr_return_quantity) AS units,
    'return' AS src
  FROM web_returns wr
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  JOIN promotion p ON p.p_item_sk = i.i_item_sk
  WHERE wr.wr_returned_date_sk BETWEEN 2450815 AND 2451179
    AND wr.wr_return_quantity > 0
  GROUP BY wr.wr_item_sk, p.p_promo_sk
),
union_sales_returns AS (
  SELECT * FROM sales_agg
  UNION ALL
  SELECT * FROM returns_agg
)
SELECT DISTINCT
  i.i_item_id,
  i.i_product_name,
  s.s_store_name,
  p.p_promo_name,
  us.src,
  SUM(us.amount) AS total_amount,
  SUM(us.units) AS total_units,
  ia.total_on_hand
FROM union_sales_returns us
JOIN item i ON us.item_sk = i.i_item_sk
LEFT JOIN store s ON us.store_sk = s.s_store_sk
JOIN promotion p ON us.promo_sk = p.p_promo_sk
JOIN inventory_agg ia ON us.item_sk = ia.inv_item_sk
WHERE i.i_category = 'Accessories'
  AND i.i_brand = 'Brand#12'
  AND p.p_discount_active = 'Y'
  AND (s.s_state = 'CA' OR s.s_state = 'TX')
  AND ia.total_on_hand > 500
  AND us.amount > 0
GROUP BY i.i_item_id, i.i_product_name, s.s_store_name, p.p_promo_name, us.src, ia.total_on_hand
HAVING SUM(us.amount) > 1000
ORDER BY total_amount DESC
LIMIT 100
