WITH distinct_sales AS (
    SELECT DISTINCT
        ws_order_number,
        ws_net_profit,
        ws_ship_mode_sk,
        ws_web_site_sk,
        ws_web_page_sk
    FROM web_sales
)
SELECT
    ds.ws_ship_mode_sk,
    sm.sm_contract,
    regexp_extract(sm.sm_contract, '([A-Za-z]+)', 1) AS contract_alpha,
    ds.ws_web_site_sk,
    ws.web_name,
    COUNT(DISTINCT ds.ws_order_number) AS distinct_orders,
    SUM(ds.ws_net_profit) AS total_profit,
    MAX(concat(CAST(ds.ws_order_number AS varchar), '-', sm.sm_code)) AS sample_order_ship_code,
    MAX(substr(wp.wp_url, 1, 10)) AS url_prefix
FROM distinct_sales ds
JOIN ship_mode sm
    ON ds.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_site ws
    ON ds.ws_web_site_sk = ws.web_site_sk
JOIN web_page wp
    ON ds.ws_web_page_sk = wp.wp_web_page_sk
WHERE regexp_like(sm.sm_contract, '\\d')
  AND wp.wp_url LIKE '%example.com%'
GROUP BY
    ds.ws_ship_mode_sk,
    sm.sm_contract,
    regexp_extract(sm.sm_contract, '([A-Za-z]+)', 1),
    ds.ws_web_site_sk,
    ws.web_name
HAVING SUM(ds.ws_net_profit) > 0
ORDER BY total_profit DESC
LIMIT 100
