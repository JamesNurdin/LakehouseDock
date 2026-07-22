WITH valid_contracts AS (
    SELECT DISTINCT sm_ship_mode_sk, sm_contract
    FROM ship_mode
    WHERE regexp_like(sm_contract, '[0-9]{2,}')
)
SELECT
    sm.sm_ship_mode_id AS ship_mode_id,
    CONCAT('Domain: ', regexp_extract(wp.wp_url, '^https?://([^/]+)', 1)) AS domain,
    substr(sm.sm_contract, 1, 5) AS contract_prefix,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
FROM web_sales ws
INNER JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
INNER JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
INNER JOIN valid_contracts vc ON vc.sm_ship_mode_sk = sm.sm_ship_mode_sk
INNER JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
INNER JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE d.d_year = 2001
  AND wp.wp_url LIKE '%product%'
  AND regexp_like(sm.sm_contract, '^[A-Z][a-z]+[0-9]+')
GROUP BY
    sm.sm_ship_mode_id,
    CONCAT('Domain: ', regexp_extract(wp.wp_url, '^https?://([^/]+)', 1)),
    substr(sm.sm_contract, 1, 5)
ORDER BY total_profit DESC
LIMIT 20
