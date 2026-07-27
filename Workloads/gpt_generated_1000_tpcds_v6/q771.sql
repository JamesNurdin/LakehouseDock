WITH ws_agg AS (
    SELECT
        ws_bill_customer_sk AS customer_sk,
        COUNT(*) AS ws_order_cnt,
        SUM(ws_net_paid_inc_tax) AS ws_total_paid,
        AVG(ws_sales_price) AS ws_avg_price
    FROM web_sales
    WHERE ws_sales_price > 20.00
      AND ws_net_paid_inc_tax BETWEEN 100.00 AND 5000.00
      AND ws_coupon_amt = 0.00
    GROUP BY ws_bill_customer_sk
    HAVING COUNT(*) >= 2
)
SELECT
    cc.cc_name,
    cc.cc_state,
    c.c_birth_country,
    ca.ca_state,
    COUNT(DISTINCT cs.cs_order_number) AS num_catalog_orders,
    SUM(cs.cs_net_paid_inc_tax) AS total_catalog_sales,
    AVG(cs.cs_sales_price) AS avg_catalog_price,
    MAX(ws_agg.ws_order_cnt) AS max_ws_orders,
    MAX(ws_agg.ws_total_paid) AS max_ws_total_paid,
    MAX(ws_agg.ws_avg_price) AS max_ws_avg_price
FROM catalog_sales cs
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
LEFT JOIN ws_agg
    ON ws_agg.customer_sk = c.c_customer_sk
WHERE cc.cc_rec_end_date = DATE '2000-12-31'
  AND cc.cc_zip = '98048'
  AND ca.ca_gmt_offset = -5.00
  AND c.c_birth_country = 'United States'
  AND cs.cs_net_paid_inc_tax > 500.00
GROUP BY
    cc.cc_name,
    cc.cc_state,
    c.c_birth_country,
    ca.ca_state
HAVING SUM(cs.cs_net_paid_inc_tax) > 10000
ORDER BY total_catalog_sales DESC
LIMIT 100
