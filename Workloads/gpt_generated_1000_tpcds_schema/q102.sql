WITH base AS (
  SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    i.i_class,
    p.p_promo_name,
    SUM(sr.sr_return_amt_inc_tax) AS total_return_amt,
    SUM(sr.sr_refunded_cash) AS total_refunded_cash
  FROM item i
  JOIN promotion p ON p.p_item_sk = i.i_item_sk
  JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
  WHERE regexp_like(i.i_product_name, '[0-9]{2}')
  GROUP BY i.i_item_id, i.i_product_name, i.i_brand, i.i_class, p.p_promo_name
)

SELECT
  i_item_id,
  i_product_name,
  substring(i_item_id, 1, 3) AS item_prefix,
  concat(i_brand, ' ', i_class) AS brand_class,
  p_promo_name,
  total_return_amt,
  total_refunded_cash,
  row_number() OVER (PARTITION BY i_item_id ORDER BY total_return_amt DESC) AS rn
FROM base
WHERE p_promo_name LIKE '%anti%'
UNION
SELECT
  i_item_id,
  i_product_name,
  substring(i_item_id, 1, 3) AS item_prefix,
  concat(i_brand, ' ', i_class) AS brand_class,
  p_promo_name,
  total_return_amt,
  total_refunded_cash,
  row_number() OVER (PARTITION BY i_item_id ORDER BY total_return_amt DESC) AS rn
FROM base
WHERE i_item_id LIKE '00%'
LIMIT 100
