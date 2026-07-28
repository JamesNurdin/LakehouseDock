WITH store_agg AS (
    SELECT
        c.c_customer_sk AS customer_sk,
        c.c_customer_id,
        c.c_birth_month,
        hd.hd_income_band_sk,
        SUM(ss.ss_net_paid) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE c.c_birth_month = 7
      AND hd.hd_dep_count >= 2
      AND c.c_preferred_cust_flag = 'Y'
    GROUP BY c.c_customer_sk, c.c_customer_id, c.c_birth_month, hd.hd_income_band_sk
),
web_agg AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        ws.ws_ship_mode_sk,
        ws.ws_web_site_sk
    FROM web_sales ws
    WHERE ws.ws_ship_mode_sk IS NOT NULL
      AND ws.ws_web_site_sk IS NOT NULL
    GROUP BY ws.ws_bill_customer_sk, ws.ws_ship_mode_sk, ws.ws_web_site_sk
)
SELECT
    sa.c_customer_id,
    sa.c_birth_month,
    sa.hd_income_band_sk,
    sa.total_store_sales,
    sa.store_transactions,
    wa.total_web_sales,
    wa.web_orders,
    ws_site.web_name,
    ws_site.web_country,
    ws_site.web_state
FROM store_agg sa
JOIN web_agg wa
    ON sa.customer_sk = wa.customer_sk
JOIN web_site ws_site
    ON wa.ws_web_site_sk = ws_site.web_site_sk
WHERE EXISTS (
    SELECT 1
    FROM ship_mode sm
    WHERE sm.sm_ship_mode_sk = wa.ws_ship_mode_sk
      AND sm.sm_code = 'AIR'
      AND sm.sm_carrier = 'DHL'
)
  AND ws_site.web_country = 'United States'
  AND ws_site.web_state = 'CA'
ORDER BY sa.total_store_sales DESC
LIMIT 100
