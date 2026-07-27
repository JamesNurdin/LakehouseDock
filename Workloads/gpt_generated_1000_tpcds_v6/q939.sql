/* goal: Analyze profitability by ship mode and country for sales rows that match specific contract patterns or suite-number patterns, using string functions, a scalar subquery for average profit, and a UNION of two filtered sets, then categorize profit levels */
WITH combined AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_ship_mode_sk,
        ws.ws_net_profit,
        w.web_country,
        w.web_suite_number,
        sm.sm_ship_mode_id,
        sm.sm_contract,
        sm.sm_carrier
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE sm.sm_contract LIKE '%F%'
    UNION ALL
    SELECT
        ws.ws_web_site_sk,
        ws.ws_ship_mode_sk,
        ws.ws_net_profit,
        w.web_country,
        w.web_suite_number,
        sm.sm_ship_mode_id,
        sm.sm_contract,
        sm.sm_carrier
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE regexp_like(w.web_suite_number, '^Suite [0-9]+$')
),
avg_profit AS (
    SELECT AVG(ws_net_profit) AS avg_profit FROM combined
)
SELECT
    c.web_country,
    c.sm_ship_mode_id,
    SUM(c.ws_net_profit) AS total_profit,
    CASE
        WHEN SUM(c.ws_net_profit) > 200000 THEN 'HIGH'
        WHEN SUM(c.ws_net_profit) > 100000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    regexp_extract(c.web_suite_number, '(\\d+)$') AS suite_num,
    CONCAT(c.sm_carrier, '-', c.sm_contract) AS carrier_contract
FROM combined c
CROSS JOIN avg_profit a
WHERE c.ws_net_profit > a.avg_profit
  AND regexp_like(c.sm_contract, '^[A-Z][a-z0-9]{5,}$')
GROUP BY
    c.web_country,
    c.sm_ship_mode_id,
    regexp_extract(c.web_suite_number, '(\\d+)$'),
    CONCAT(c.sm_carrier, '-', c.sm_contract)
HAVING COUNT(*) > 5
ORDER BY total_profit DESC
LIMIT 100
