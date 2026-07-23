WITH joined_data AS (
    SELECT
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        ws.ws_quantity,
        ws.ws_ship_mode_sk,
        sm.sm_ship_mode_sk,
        sm.sm_carrier,
        sm.sm_code,
        td.t_hour,
        td.t_am_pm,
        wsit.web_city,
        wsit.web_state,
        wsit.web_suite_number,
        wsit.web_name,
        concat(wsit.web_city, ', ', wsit.web_state) AS site_location,
        CAST(regexp_extract(wsit.web_suite_number, '\\d+', 0) AS integer) AS suite_number_numeric,
        substring(wsit.web_suite_number, 7) AS suite_number_substring
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE regexp_like(sm.sm_carrier, '^UPS.*')
      AND td.t_am_pm = 'PM'
      AND CAST(regexp_extract(wsit.web_suite_number, '\\d+', 0) AS integer) > 300
)
SELECT
    sm_carrier,
    sm_code,
    t_hour,
    t_am_pm,
    site_location,
    sum(ws_net_profit) AS total_net_profit,
    sum(ws_ext_sales_price) AS total_sales_price,
    sum(ws_quantity) AS total_quantity,
    avg(ws_quantity) AS avg_quantity,
    sum(CASE WHEN web_name LIKE '%Site%' THEN 1 ELSE 0 END) AS site_name_like_count,
    sum(ws_net_profit) / (
        SELECT sum(ws2.ws_net_profit)
        FROM web_sales ws2
        WHERE ws2.ws_ship_mode_sk = joined_data.sm_ship_mode_sk
    ) AS profit_share
FROM joined_data
GROUP BY sm_carrier, sm_code, t_hour, t_am_pm, site_location, sm_ship_mode_sk
ORDER BY total_net_profit DESC
LIMIT 100
