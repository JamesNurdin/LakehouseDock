WITH store_sales_agg AS (
    SELECT
        'Store' AS sales_channel,
        i.i_item_id,
        i.i_item_desc,
        p.p_promo_name,
        td.t_hour,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND i.i_units = 'Each'
    GROUP BY
        i.i_item_id,
        i.i_item_desc,
        p.p_promo_name,
        td.t_hour
),
web_sales_agg AS (
    SELECT
        'Web' AS sales_channel,
        i.i_item_id,
        i.i_item_desc,
        p.p_promo_name,
        td.t_hour,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND i.i_units = 'Each'
    GROUP BY
        i.i_item_id,
        i.i_item_desc,
        p.p_promo_name,
        td.t_hour
)
SELECT *
FROM store_sales_agg
UNION ALL
SELECT *
FROM web_sales_agg
ORDER BY total_net_paid DESC
LIMIT 100
