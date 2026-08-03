WITH ss_agg AS (
    SELECT
        ss.ss_store_sk,
        d.d_date,
        SUM(ss.ss_ext_sales_price) AS store_sales_total,
        COUNT(*) AS store_txn_cnt,
        AVG(ss.ss_net_profit) AS avg_store_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss.ss_store_sk, d.d_date
),
ws_agg AS (
    SELECT
        ws.ws_web_page_sk,
        d_sold.d_date AS sold_date,
        SUM(ws.ws_ext_sales_price) AS web_sales_total,
        AVG(ws.ws_net_profit) AS avg_web_profit
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    GROUP BY ws.ws_web_page_sk, d_sold.d_date
),
cross_vals AS (
    SELECT *
    FROM (VALUES (1, 'Low'), (2, 'Medium'), (3, 'High')) AS t(level, label)
)
SELECT
    s.s_store_name,
    cc.cc_name,
    wp.wp_url,
    sa.store_sales_total,
    wa.web_sales_total,
    cv.label,
    CASE
        WHEN sa.store_sales_total > 200000 THEN 'Platinum'
        WHEN sa.store_sales_total > 100000 THEN 'Gold'
        ELSE 'Silver'
    END AS store_sales_tier,
    (
        SELECT COUNT(*)
        FROM web_sales ws_sub
        WHERE ws_sub.ws_web_page_sk = wp.wp_web_page_sk
          AND ws_sub.ws_ext_sales_price > 1000
    ) AS high_value_txn_cnt
FROM ss_agg sa
JOIN store s ON sa.ss_store_sk = s.s_store_sk
JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN call_center cc ON cc.cc_closed_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN ws_agg wa ON sa.d_date = wa.sold_date
JOIN web_page wp ON wa.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN cross_vals cv ON cv.level = CASE
    WHEN sa.store_sales_total > 200000 THEN 3
    WHEN sa.store_sales_total > 100000 THEN 2
    ELSE 1
END
WHERE d_store_closed.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  AND s.s_state = 'CA'
  AND wp.wp_max_ad_count > 0
  AND EXISTS (
        SELECT 1
        FROM web_sales ws_check
        WHERE ws_check.ws_web_page_sk = wp.wp_web_page_sk
          AND ws_check.ws_ext_sales_price > 1500
    )
LIMIT 100
