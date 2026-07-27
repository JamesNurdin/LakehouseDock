WITH filtered_sales AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_ext_list_price,
        ws.ws_net_profit,
        ws.ws_order_number
    FROM web_sales ws
    WHERE ws.ws_ext_list_price > (
        SELECT avg(ws2.ws_ext_list_price) * 0.8
        FROM web_sales ws2
        WHERE ws2.ws_web_site_sk = ws.ws_web_site_sk
    )
)
SELECT
    wsit.web_name,
    wsit.web_city,
    wsit.web_state,
    COUNT(DISTINCT fs.ws_order_number) AS distinct_orders,
    SUM(fs.ws_net_profit) AS total_net_profit,
    AVG(fs.ws_ext_list_price) AS avg_ext_list_price,
    CONCAT(wsit.web_city, ', ', wsit.web_state) AS location
FROM filtered_sales fs
JOIN web_site wsit
    ON fs.ws_web_site_sk = wsit.web_site_sk
WHERE
    regexp_like(wsit.web_street_name, '(?i)^west')
    AND wsit.web_county LIKE '%County'
    AND substring(wsit.web_name, 1, 3) = 'Web'
GROUP BY
    wsit.web_name,
    wsit.web_city,
    wsit.web_state
ORDER BY total_net_profit DESC
LIMIT 100
