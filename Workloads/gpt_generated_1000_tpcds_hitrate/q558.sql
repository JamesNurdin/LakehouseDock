WITH filtered_customers AS (
    SELECT
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_birth_month,
        c_birth_day,
        c_salutation
    FROM tpcds.customer
    WHERE c_birth_month = 5
      AND c_birth_day BETWEEN 10 AND 20
      AND c_salutation = 'Ms.'
)
SELECT
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    sm.sm_type,
    w.w_warehouse_name,
    COUNT(DISTINCT ws.ws_item_sk) AS distinct_items,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    SUM(CASE WHEN ib.ib_upper_bound > 100000 THEN ws.ws_ext_sales_price ELSE 0 END) AS high_income_sales,
    SUM(ss.ss_net_profit) AS store_net_profit
FROM tpcds.web_sales ws
JOIN filtered_customers c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN tpcds.household_demographics hd
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN tpcds.ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.store_sales ss
    ON ss.ss_customer_sk = c.c_customer_sk
   AND ss.ss_hdemo_sk = hd.hd_demo_sk
WHERE w.w_warehouse_sq_ft > 500000
  AND ws.ws_ext_tax < 50
  AND sm.sm_carrier = 'UPS'
  AND EXISTS (
        SELECT 1
        FROM tpcds.store_sales ss2
        WHERE ss2.ss_customer_sk = c.c_customer_sk
          AND ss2.ss_ext_sales_price > 1000
        LIMIT 1
    )
GROUP BY ws.ws_order_number, ws.ws_sold_date_sk, sm.sm_type, w.w_warehouse_name
HAVING SUM(ws.ws_ext_sales_price) > 5000
ORDER BY total_sales DESC
LIMIT 100
