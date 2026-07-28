WITH store_data AS (
    SELECT 
        i.i_item_id AS item_id,
        s.s_store_name AS channel,
        SUM(ss.ss_net_paid) AS total_net_paid
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_item_id, s.s_store_name
),
web_data AS (
    SELECT 
        i.i_item_id AS item_id,
        w.web_name AS channel,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_item_id, w.web_name
)
SELECT DISTINCT
    t.item_id,
    t.channel,
    t.total_net_paid
FROM (
    SELECT item_id, channel, total_net_paid FROM store_data
    UNION ALL
    SELECT item_id, channel, total_net_paid FROM web_data
) t
ORDER BY t.total_net_paid DESC
LIMIT 100
