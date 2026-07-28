WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_promo_sk,
        ws.ws_web_page_sk,
        ws.ws_sold_time_sk
    FROM tpcds.web_sales ws
    JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE regexp_like(p.p_promo_name, '(?i)discount')
      AND wp.wp_url LIKE '%example.com%'
)
SELECT
    p.p_promo_id,
    p.p_promo_name,
    regexp_extract(p.p_promo_name, '(?i)(discount.*)', 1) AS promo_keyword,
    concat(p.p_promo_name, ' - ', wp.wp_type) AS promo_page_type,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_net_profit) AS total_net_profit,
    MIN(t.t_time) AS earliest_time,
    MAX(t.t_time) AS latest_time
FROM filtered_sales ws
JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
GROUP BY
    p.p_promo_id,
    p.p_promo_name,
    regexp_extract(p.p_promo_name, '(?i)(discount.*)', 1),
    concat(p.p_promo_name, ' - ', wp.wp_type)
ORDER BY total_net_profit DESC
LIMIT 100
