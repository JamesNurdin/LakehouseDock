WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_quantity,
        d.d_year,
        d.d_fy_week_seq,
        sm.sm_type,
        sm.sm_carrier,
        wsite.web_name,
        wsite.web_class
    FROM web_sales ws
    JOIN date_dim d
      ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site wsite
      ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE d.d_year = 2002
      AND d.d_fy_week_seq BETWEEN 10 AND 20
      AND regexp_like(sm.sm_type, '^AIR')
      AND wsite.web_name LIKE '%Shop%'
)
SELECT
    sm_type,
    sm_carrier,
    substring(web_class, 1, 3) AS class_prefix,
    regexp_extract(web_name, '([A-Za-z]+)') AS first_word,
    COUNT(DISTINCT ws_order_number) AS orders,
    SUM(ws_quantity) AS total_quantity,
    SUM(ws_net_profit) AS total_profit,
    any_value(concat(cast(ws_order_number AS varchar), '-', sm_type)) AS sample_label
FROM filtered_sales
GROUP BY
    sm_type,
    sm_carrier,
    substring(web_class, 1, 3),
    regexp_extract(web_name, '([A-Za-z]+)')
ORDER BY total_profit DESC
LIMIT 100
