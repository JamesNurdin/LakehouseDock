WITH sales AS (
  SELECT ss_item_sk, ss_ticket_number, ss_net_profit, ss_sold_time_sk, ss_promo_sk, ss_hdemo_sk
  FROM store_sales
),
returns AS (
  SELECT sr_item_sk, sr_ticket_number, sr_net_loss, sr_return_time_sk, sr_hdemo_sk
  FROM store_returns
),
item_not_sold AS (
  SELECT inv_item_sk FROM inventory WHERE inv_quantity_on_hand > 0
  EXCEPT
  SELECT ss_item_sk FROM store_sales
),
max_pop_item AS (
  SELECT max(i_item_sk) AS max_sk FROM item WHERE i_category = 'pop'
)
SELECT
  i.i_item_sk,
  i.i_product_name,
  i.i_brand,
  i.i_category,
  substring(i.i_product_name FROM 1 FOR 15) AS product_prefix,
  regexp_extract(i.i_product_name, '(\\w+)', 1) AS first_word,
  CASE WHEN regexp_like(i.i_product_name, '(?i)elite') THEN 'Elite' ELSE 'Other' END AS elite_flag,
  COALESCE(s.ss_net_profit, 0) - COALESCE(r.sr_net_loss, 0) AS net_adjusted_profit,
  t.t_hour,
  p.p_promo_name,
  prod_sub.short_name
FROM sales s
FULL OUTER JOIN returns r
  ON s.ss_item_sk = r.sr_item_sk AND s.ss_ticket_number = r.sr_ticket_number
JOIN item i
  ON (s.ss_item_sk = i.i_item_sk OR r.sr_item_sk = i.i_item_sk)
LEFT JOIN promotion p
  ON s.ss_promo_sk = p.p_promo_sk
LEFT JOIN time_dim t
  ON (s.ss_sold_time_sk = t.t_time_sk OR r.sr_return_time_sk = t.t_time_sk)
CROSS JOIN LATERAL (
  SELECT substring(i.i_product_name FROM 1 FOR 5) AS short_name
) AS prod_sub
WHERE
  regexp_like(i.i_product_name, '(?i)elite')
  AND i.i_brand LIKE 'A%'
  AND i.i_category_id = (
    SELECT ib_income_band_sk FROM income_band WHERE ib_lower_bound = 5000 LIMIT 1
  )
  AND i.i_item_sk IN (SELECT inv_item_sk FROM item_not_sold)
  AND EXISTS (
    SELECT 1 FROM household_demographics hd
    WHERE hd.hd_demo_sk = COALESCE(s.ss_hdemo_sk, r.sr_hdemo_sk)
      AND hd.hd_buy_potential LIKE '%1000%'
  )
  AND i.i_item_sk = (SELECT max_sk FROM max_pop_item)
ORDER BY net_adjusted_profit DESC
LIMIT 100
