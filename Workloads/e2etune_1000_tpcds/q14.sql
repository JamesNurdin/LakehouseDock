WITH store_agg AS (
    SELECT
        ss.ss_promo_sk AS promo_sk,
        ss.ss_hdemo_sk AS hd_demo_sk,
        COUNT(*) AS store_txn_cnt,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        AVG(ss.ss_ext_discount_amt) AS store_avg_discount
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'N'
        AND ss.ss_quantity > 0
    GROUP BY ss.ss_promo_sk, ss.ss_hdemo_sk
),
web_agg AS (
    SELECT
        ws.ws_promo_sk AS promo_sk,
        ws.ws_bill_hdemo_sk AS hd_demo_sk,
        ws.ws_web_page_sk AS web_page_sk,
        COUNT(*) AS web_txn_cnt,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        AVG(ws.ws_ext_discount_amt) AS web_avg_discount
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'N'
        AND ws.ws_quantity > 0
    GROUP BY ws.ws_promo_sk, ws.ws_bill_hdemo_sk, ws.ws_web_page_sk
)
SELECT
    p.p_promo_name,
    hd.hd_income_band_sk,
    wp.wp_type,
    COALESCE(sa.store_txn_cnt, 0) AS store_txn_cnt,
    COALESCE(wa.web_txn_cnt, 0) AS web_txn_cnt,
    COALESCE(sa.store_net_profit, 0) + COALESCE(wa.web_net_profit, 0) AS total_net_profit,
    COALESCE(sa.store_sales, 0) + COALESCE(wa.web_sales, 0) AS total_sales,
    COALESCE(sa.store_avg_discount, 0) AS avg_store_discount,
    COALESCE(wa.web_avg_discount, 0) AS avg_web_discount
FROM store_agg sa
FULL OUTER JOIN web_agg wa
    ON sa.promo_sk = wa.promo_sk
    AND sa.hd_demo_sk = wa.hd_demo_sk
JOIN promotion p ON COALESCE(sa.promo_sk, wa.promo_sk) = p.p_promo_sk
JOIN household_demographics hd ON COALESCE(sa.hd_demo_sk, wa.hd_demo_sk) = hd.hd_demo_sk
LEFT JOIN web_page wp ON wa.web_page_sk = wp.wp_web_page_sk
WHERE hd.hd_income_band_sk IN (3, 4, 5)
    AND hd.hd_vehicle_count >= 1
    AND (COALESCE(sa.store_sales, 0) + COALESCE(wa.web_sales, 0)) > 5000
ORDER BY total_sales DESC
LIMIT 100
