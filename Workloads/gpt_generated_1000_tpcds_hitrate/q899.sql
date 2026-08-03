WITH sales_union AS (
    -- Store sales side of the union
    SELECT
        s.s_store_name AS location_name,
        t.t_hour AS hour_of_day,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        'store' AS sales_channel
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE s.s_state = 'CA'
      AND ss.ss_quantity > 0

    UNION

    -- Web sales side of the union
    SELECT
        w.web_name AS location_name,
        t.t_hour AS hour_of_day,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        'web' AS sales_channel
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE w.web_state = 'CA'
      AND ws.ws_quantity > 0
)
SELECT
    location_name,
    hour_of_day,
    sales_channel,
    sum_net_paid,
    sum_net_profit,
    ROW_NUMBER() OVER (ORDER BY sum_net_paid DESC) AS row_num
FROM (
    SELECT
        location_name,
        hour_of_day,
        sales_channel,
        SUM(net_paid) AS sum_net_paid,
        SUM(net_profit) AS sum_net_profit
    FROM sales_union
    GROUP BY GROUPING SETS (
        (location_name, hour_of_day, sales_channel),
        (location_name, sales_channel),
        (sales_channel)
    )
) agg
LIMIT 100
