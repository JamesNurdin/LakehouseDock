WITH cr_dim AS (
   SELECT
       cr.cr_return_quantity,
       cr.cr_return_amount,
       cr.cr_returned_date_sk,
       cr.cr_call_center_sk,
       cr.cr_catalog_page_sk,
       cr.cr_refunded_hdemo_sk,
       cr.cr_refunded_addr_sk,
       cc.cc_name,
       cc.cc_state,
       cp.cp_type,
       cp.cp_catalog_number,
       ca.ca_city,
       hd.hd_buy_potential,
       hd.hd_income_band_sk,
       hd.hd_demo_sk
   FROM catalog_returns cr
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
   JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   WHERE cc.cc_state IN ('CA', 'TX', 'NY')
     AND cp.cp_type = 'monthly'
     AND ca.ca_city LIKE '%Street%'
     AND hd.hd_income_band_sk BETWEEN 5 AND 10
)
SELECT
   ws.ws_order_number,
   ws.ws_sold_date_sk,
   crd.cc_name,
   crd.cp_type,
   crd.ca_city,
   crd.hd_buy_potential,
   wp.wp_char_count,
   CASE
       WHEN ws.ws_net_profit > 0 THEN 'Profitable'
       WHEN ws.ws_net_profit = 0 THEN 'Break-even'
       ELSE 'Loss'
   END AS profit_category,
   ROW_NUMBER() OVER (PARTITION BY crd.cc_name ORDER BY ws.ws_ext_sales_price DESC) AS rn_profit_by_center,
   SUM(ws.ws_ext_sales_price) OVER (
       PARTITION BY crd.cp_type
       ORDER BY ws.ws_sold_date_sk
       ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
   ) AS moving_sum_4_rows,
   (
       SELECT COUNT(*)
       FROM catalog_returns cr2
       WHERE cr2.cr_call_center_sk = crd.cr_call_center_sk
         AND cr2.cr_return_amount > 500
   ) AS high_return_count
FROM web_sales ws
JOIN cr_dim crd ON ws.ws_bill_hdemo_sk = crd.hd_demo_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE ws.ws_sold_date_sk BETWEEN 2451084 AND 2451543
  AND ws.ws_ext_sales_price > 200
  AND ws.ws_quantity >= 2
  AND ws.ws_net_profit IS NOT NULL
  AND ws.ws_ext_discount_amt < 300
  AND ws.ws_coupon_amt BETWEEN 0 AND 50
  AND wp.wp_char_count > 2000
ORDER BY ws.ws_sold_date_sk DESC, ws.ws_ext_sales_price DESC
LIMIT 100
