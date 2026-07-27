WITH filtered_sales AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_promo_sk,
        ws.ws_sold_time_sk,
        ws.ws_order_number,
        ws.ws_net_profit
    FROM
        tpcds.web_sales ws
    JOIN
        tpcds.time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN
        tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE
        td.t_meal_time = 'lunch'
        AND regexp_like(p.p_promo_name, '^DISCOUNT_.*')
) 
SELECT
    ws_site.web_name,
    ws_site.web_city,
    substring(ws_site.web_city, 1, 3) AS city_prefix,
    regexp_extract(p.p_promo_name, '(\\d+)', 1) AS promo_number,
    SUM(sales.ws_net_profit) AS total_profit,
    CASE WHEN SUM(sales.ws_net_profit) > 0 THEN 'Positive' ELSE 'Non-Positive' END AS profit_flag,
    COUNT(DISTINCT sales.ws_order_number) AS distinct_orders
FROM
    filtered_sales sales
JOIN
    tpcds.web_sales ws ON sales.ws_order_number = ws.ws_order_number
JOIN
    tpcds.web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN
    tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
WHERE
    ws_site.web_name LIKE '%Shop%'
GROUP BY
    ws_site.web_name,
    ws_site.web_city,
    substring(ws_site.web_city, 1, 3),
    regexp_extract(p.p_promo_name, '(\\d+)', 1)
ORDER BY
    total_profit DESC
LIMIT 100
