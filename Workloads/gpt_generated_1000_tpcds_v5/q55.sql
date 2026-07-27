WITH hd_income AS (
    SELECT 
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CONCAT(CAST(ib.ib_lower_bound AS varchar), '-', CAST(ib.ib_upper_bound AS varchar)) AS income_range
    FROM household_demographics hd
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE regexp_like(hd.hd_buy_potential, '^[0-9]+-[0-9]+$')
)
SELECT
    hi.income_range,
    COUNT(DISTINCT sr.sr_ticket_number) AS num_returns,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(sr.sr_return_amt) AS avg_return_amount,
    SUM(ws.ws_net_profit) AS total_web_profit,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_pages,
    array_agg(DISTINCT regexp_extract(wp.wp_url, 'https?://([^/]+)', 1)) AS domains,
    SUM(sr.sr_return_amt) - (SELECT AVG(sr2.sr_return_amt) FROM store_returns sr2) AS return_vs_overall_avg
FROM hd_income hi
JOIN store_returns sr
    ON sr.sr_hdemo_sk = hi.hd_demo_sk
JOIN web_sales ws
    ON ws.ws_bill_hdemo_sk = hi.hd_demo_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE
    regexp_like(wp.wp_url, '^https?://[^/]+\\.com/')
    AND wp.wp_type LIKE 'product%'
    AND EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_ship_hdemo_sk = hi.hd_demo_sk
          AND ws2.ws_ext_sales_price > 1000
    )
GROUP BY hi.income_range
ORDER BY total_return_amount DESC
LIMIT 100
