WITH sampled_ws AS (
    SELECT
        ws_sold_time_sk,
        ws_bill_hdemo_sk,
        ws_web_page_sk,
        ws_net_profit,
        ws_net_paid_inc_ship
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE ws_net_paid_inc_ship > 500
)
SELECT
    td.t_meal_time,
    CONCAT(CAST(td.t_hour AS varchar), ':', LPAD(CAST(td.t_minute AS varchar), 2, '0')) AS time_of_day,
    REGEXP_EXTRACT(wp.wp_url, 'https?://([^/]+)', 1) AS domain,
    SUBSTRING(wp.wp_web_page_id, 1, 4) AS page_id_prefix,
    hd.hd_demo_sk,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_net_paid_inc_ship) AS avg_paid_inc_ship,
    (
        SELECT SUM(cs.cs_net_profit)
        FROM catalog_sales cs
        WHERE cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    ) AS catalog_total_profit_for_demo
FROM sampled_ws ws
JOIN time_dim td
    ON ws.ws_sold_time_sk = td.t_time_sk
JOIN household_demographics hd
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE
    REGEXP_LIKE(wp.wp_url, '^https?://.*\\.com')
    AND wp.wp_web_page_id LIKE 'AAAA%'
GROUP BY
    td.t_meal_time,
    td.t_hour,
    td.t_minute,
    REGEXP_EXTRACT(wp.wp_url, 'https?://([^/]+)', 1),
    SUBSTRING(wp.wp_web_page_id, 1, 4),
    hd.hd_demo_sk
ORDER BY total_net_profit DESC
LIMIT 100
