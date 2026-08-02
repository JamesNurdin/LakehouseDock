WITH ss_agg AS (
    SELECT
        ss_store_sk,
        ss_customer_sk,
        SUM(ss_net_paid_inc_tax) AS total_store_net_paid,
        COUNT(*) AS store_sales_cnt
    FROM store_sales
    WHERE ss_net_paid_inc_tax > 100.00
    GROUP BY ss_store_sk, ss_customer_sk
),
ws_agg AS (
    SELECT
        ws_web_page_sk,
        ws_ship_mode_sk,
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_web_net_paid,
        COUNT(*) AS web_sales_cnt
    FROM web_sales
    WHERE ws_net_paid_inc_tax > 100.00
    GROUP BY ws_web_page_sk, ws_ship_mode_sk, ws_bill_customer_sk
)
SELECT
    s1.s_store_name,
    s2.s_tax_percentage,
    cust_ss.c_customer_id AS store_cust_id,
    cust_wp.c_customer_id AS web_cust_id,
    sm1.sm_type AS ship_type,
    sm2.sm_contract AS ship_contract,
    sm3.sm_code AS ship_code,
    ss_agg.total_store_net_paid,
    ws_agg.total_web_net_paid,
    ROW_NUMBER() OVER (PARTITION BY s1.s_store_name ORDER BY ss_agg.total_store_net_paid DESC) AS store_sales_rank,
    COUNT(*) OVER (PARTITION BY cust_ss.c_customer_id) AS purchase_days_count
FROM ss_agg
JOIN "store" AS s1 ON ss_agg.ss_store_sk = s1.s_store_sk
JOIN "store" AS s2 ON ss_agg.ss_store_sk = s2.s_store_sk
JOIN "customer" AS cust_ss ON ss_agg.ss_customer_sk = cust_ss.c_customer_sk
JOIN ws_agg ON ws_agg.ws_bill_customer_sk = cust_ss.c_customer_sk
JOIN ship_mode AS sm1 ON ws_agg.ws_ship_mode_sk = sm1.sm_ship_mode_sk
JOIN ship_mode AS sm2 ON ws_agg.ws_ship_mode_sk = sm2.sm_ship_mode_sk
JOIN ship_mode AS sm3 ON ws_agg.ws_ship_mode_sk = sm3.sm_ship_mode_sk
JOIN web_page AS wp ON ws_agg.ws_web_page_sk = wp.wp_web_page_sk
JOIN "customer" AS cust_wp ON wp.wp_customer_sk = cust_wp.c_customer_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM store_sales ss2
    WHERE ss2.ss_customer_sk = cust_ss.c_customer_sk
      AND ss2.ss_net_paid_inc_tax > 5000.00
)
  AND EXISTS (
    SELECT 1
    FROM web_sales ws2
    WHERE ws2.ws_bill_customer_sk = cust_ss.c_customer_sk
      AND ws2.ws_net_paid_inc_tax > 2000.00
)
ORDER BY ss_agg.total_store_net_paid DESC, ws_agg.total_web_net_paid DESC
LIMIT 100
