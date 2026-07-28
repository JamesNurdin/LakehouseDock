WITH filtered_ws AS (
  SELECT ws_sold_date_sk,
         ws_item_sk,
         ws_bill_customer_sk,
         ws_ext_sales_price,
         ws_web_page_sk,
         ws_net_paid
  FROM web_sales
  WHERE ws_ext_sales_price > 500
    AND ws_sold_date_sk BETWEEN 2450000 AND 2455000
),
filtered_i AS (
  SELECT i_item_sk,
         i_category,
         i_current_price,
         i_category_id
  FROM item
  WHERE i_current_price BETWEEN 100 AND 500
)
SELECT
  s.s_state,
  i.i_category,
  hd.hd_buy_potential,
  COUNT(DISTINCT c.c_customer_id)               AS distinct_customers,
  SUM(ws.ws_ext_sales_price)                   AS total_web_sales,
  SUM(COALESCE(sr.sr_return_amt, 0))           AS total_store_returns,
  AVG(i.i_current_price)                       AS avg_item_price,
  CASE
    WHEN SUM(ws.ws_ext_sales_price) > 100000 THEN 'High'
    ELSE 'Low'
  END                                          AS sales_volume_category,
  (SELECT AVG(i2.i_current_price)
   FROM item i2
   WHERE i2.i_category = i.i_category)        AS avg_price_same_category
FROM filtered_ws ws
JOIN filtered_i i
  ON ws.ws_item_sk = i.i_item_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN customer c
  ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
  ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
  ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON c.c_current_hdemo_sk = hd.hd_demo_sk
LEFT JOIN store_returns sr
  ON sr.sr_item_sk = i.i_item_sk
LEFT JOIN store s
  ON sr.sr_store_sk = s.s_store_sk
WHERE s.s_state = 'CA'
  AND hd.hd_income_band_sk IN (10, 15)
  AND cd.cd_gender = 'M'
  AND wp.wp_type = 'Content'
GROUP BY
  s.s_state,
  i.i_category,
  hd.hd_buy_potential
ORDER BY total_web_sales DESC
LIMIT 100
