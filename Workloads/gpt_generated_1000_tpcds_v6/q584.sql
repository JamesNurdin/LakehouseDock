WITH ss_hd_ib AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        hd.hd_demo_sk,
        hd.hd_vehicle_count,
        hd.hd_dep_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM store_sales ss
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ss.ss_quantity >= 50
      AND ss.ss_wholesale_cost BETWEEN 20 AND 80
      AND ib.ib_upper_bound <= 150000
)

SELECT
    ss_hd_ib.ib_lower_bound,
    ss_hd_ib.ib_upper_bound,
    COUNT(DISTINCT ss_hd_ib.hd_demo_sk) AS household_cnt,
    SUM(ss_hd_ib.ss_ext_sales_price) AS total_store_sales,
    AVG(ss_hd_ib.ss_net_profit) AS avg_store_profit,
    CASE
        WHEN SUM(ss_hd_ib.ss_ext_sales_price) > 1000000 THEN 'High'
        ELSE 'Medium'
    END AS sales_category,
    SUM(ws_agg.web_sales_cnt) AS total_web_sales,
    ws_site.web_name
FROM ss_hd_ib
LEFT JOIN (
    SELECT
        ws.ws_bill_hdemo_sk,
        ws.ws_web_site_sk,
        COUNT(*) AS web_sales_cnt
    FROM web_sales ws
    GROUP BY ws.ws_bill_hdemo_sk, ws.ws_web_site_sk
) ws_agg
    ON ws_agg.ws_bill_hdemo_sk = ss_hd_ib.hd_demo_sk
JOIN web_site ws_site
    ON ws_agg.ws_web_site_sk = ws_site.web_site_sk
WHERE EXISTS (
    SELECT 1
    FROM web_sales ws2
    JOIN web_site ws2_site
        ON ws2.ws_web_site_sk = ws2_site.web_site_sk
    WHERE ws2.ws_bill_hdemo_sk = ss_hd_ib.hd_demo_sk
      AND ws2.ws_ext_sales_price > 5000
      AND ws2_site.web_state = 'CA'
)
GROUP BY
    ss_hd_ib.ib_lower_bound,
    ss_hd_ib.ib_upper_bound,
    ws_site.web_name
ORDER BY total_store_sales DESC
LIMIT 100
