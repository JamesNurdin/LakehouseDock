WITH site_sales AS (
    SELECT
        ws.ws_web_site_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(*) AS order_cnt,
        MIN(ws.ws_sold_date_sk) AS min_sold_date_sk,
        MAX(ws.ws_sold_date_sk) AS max_sold_date_sk
    FROM web_sales ws
    GROUP BY ws.ws_web_site_sk
)
SELECT
    wsit.web_site_id,
    wsit.web_name,
    wsit.web_city,
    ss.total_net_profit,
    ss.order_cnt,
    regexp_extract(wsit.web_city, '([A-Z][a-z]+)', 1) AS city_first_word,
    CONCAT(wsit.web_state, '-', wsit.web_zip) AS state_zip
FROM site_sales ss
JOIN web_site wsit
    ON ss.ws_web_site_sk = wsit.web_site_sk
WHERE
    regexp_like(wsit.web_name, '^.*[0-9]{2}.*$')
    AND wsit.web_city LIKE 'S%'
    AND NOT EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_web_site_sk = wsit.web_site_sk
          AND ws2.ws_sold_date_sk BETWEEN 2450000 AND 2450500
    )
    AND ss.total_net_profit > (
        SELECT AVG(t.total_net_profit)
        FROM (
            SELECT SUM(ws3.ws_net_profit) AS total_net_profit
            FROM web_sales ws3
            GROUP BY ws3.ws_web_site_sk
        ) t
    )
ORDER BY ss.total_net_profit DESC
LIMIT 100
