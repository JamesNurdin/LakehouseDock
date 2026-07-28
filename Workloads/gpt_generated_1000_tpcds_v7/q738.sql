WITH filtered_ship AS (
    SELECT sm_ship_mode_sk,
           sm_carrier,
           sm_contract
    FROM ship_mode
    WHERE regexp_like(sm_carrier, '^G')
),
filtered_warehouse AS (
    SELECT w_warehouse_sk,
           w_city,
           w_suite_number,
           regexp_extract(w_suite_number, '\\d+') AS suite_num
    FROM warehouse
    WHERE w_street_name LIKE '%Elm%'
)
SELECT
    sm.sm_carrier,
    wf.w_city,
    wf.suite_num,
    concat(sm.sm_carrier, '-', wf.w_city) AS carrier_city_key,
    sum(ws.ws_net_profit) AS total_profit,
    count(*) AS order_cnt,
    avg(ws.ws_ext_tax) AS avg_tax
FROM web_sales ws
JOIN filtered_ship sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN filtered_warehouse wf ON ws.ws_warehouse_sk = wf.w_warehouse_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
WHERE wsite.web_name LIKE '%Online%'
GROUP BY sm.sm_carrier, wf.w_city, wf.suite_num, concat(sm.sm_carrier, '-', wf.w_city)
HAVING sum(ws.ws_net_profit) > 1000
ORDER BY total_profit DESC
LIMIT 100
