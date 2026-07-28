WITH store_data AS (
  SELECT
    c.c_customer_id,
    ib.ib_income_band_sk,
    ss.ss_net_paid AS sales_amount,
    ss.ss_ext_discount_amt AS discount_amount,
    CASE WHEN ss.ss_quantity > 5 THEN 'Large' ELSE 'Small' END AS order_size,
    'store' AS channel
  FROM tpcds.store_sales ss
  JOIN tpcds.customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN tpcds.household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN tpcds.income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN tpcds.promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  WHERE p.p_discount_active = 'Y'
    AND ss.ss_net_paid > 100
),
web_data AS (
  SELECT
    c.c_customer_id,
    ib.ib_income_band_sk,
    ws.ws_net_paid AS sales_amount,
    ws.ws_ext_discount_amt AS discount_amount,
    CASE WHEN ws.ws_quantity > 5 THEN 'Large' ELSE 'Small' END AS order_size,
    'web' AS channel
  FROM tpcds.web_sales ws
  JOIN tpcds.customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN tpcds.household_demographics hd
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN tpcds.income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN tpcds.promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
  WHERE p.p_discount_active = 'Y'
    AND ws.ws_net_paid > 100
)
SELECT *
FROM (
  SELECT * FROM store_data
  UNION ALL
  SELECT * FROM web_data
) combined
ORDER BY sales_amount DESC
LIMIT 100
