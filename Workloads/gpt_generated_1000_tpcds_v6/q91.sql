WITH sales_data AS (
  SELECT
    ss.ss_item_sk,
    ss.ss_customer_sk,
    ss.ss_hdemo_sk,
    ss.ss_promo_sk,
    ss.ss_sales_price,
    ss.ss_net_paid,
    ss.ss_quantity,
    ss.ss_ext_discount_amt,
    ss.ss_net_profit,
    i.i_category,
    i.i_units,
    i.i_item_id,
    c.c_preferred_cust_flag,
    c.c_birth_year,
    hd.hd_income_band_sk,
    hd.hd_buy_potential,
    p.p_promo_id,
    p.p_discount_active
  FROM store_sales ss
  INNER JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
  INNER JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  INNER JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
    AND p.p_discount_active = 'Y'
  WHERE ss.ss_sales_price > 30
    AND i.i_units = 'Each'
    AND c.c_birth_year BETWEEN 1970 AND 1990
    AND hd.hd_income_band_sk IN (1, 2, 3)
)
SELECT
  i_category,
  c_preferred_cust_flag,
  hd_buy_potential,
  CASE WHEN ss_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_status,
  COALESCE(p_promo_id, 'NoPromo') AS promo_id,
  SUM(ss_net_paid) AS total_net_paid,
  AVG(ss_sales_price) AS avg_sales_price,
  SUM(ss_quantity) AS total_quantity,
  MIN(ss_sales_price) AS min_sales_price,
  MAX(ss_sales_price) AS max_sales_price,
  COUNT(*) AS transaction_cnt
FROM sales_data
GROUP BY
  i_category,
  c_preferred_cust_flag,
  hd_buy_potential,
  CASE WHEN ss_net_profit > 0 THEN 'Profit' ELSE 'Loss' END,
  COALESCE(p_promo_id, 'NoPromo')
ORDER BY total_net_paid DESC
LIMIT 100
