SELECT
  cd.cd_gender,
  i.i_brand,
  p.p_promo_name,
  COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
  SUM(wr.wr_return_amt) AS total_return_amt,
  AVG(wr.wr_return_quantity) AS avg_return_qty,
  MIN(wr.wr_return_amt_inc_tax) AS min_return_inc_tax,
  MAX(wr.wr_return_amt_inc_tax) AS max_return_inc_tax
FROM web_returns wr
JOIN item i
  ON wr.wr_item_sk = i.i_item_sk
JOIN promotion p
  ON p.p_item_sk = i.i_item_sk
JOIN customer_demographics cd
  ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE cd.cd_gender = 'F'
  AND i.i_current_price > 15
  AND p.p_discount_active = 'Y'
  AND wr.wr_return_quantity >= 2
GROUP BY cd.cd_gender, i.i_brand, p.p_promo_name
ORDER BY total_return_amt DESC
LIMIT 100
