/* goal: Compare daily net paid sales from store and web channels, include total inventory for each day, and keep only days with positive inventory. */
WITH store_agg AS (
    SELECT
        d.d_date        AS sales_date,
        d.d_date_sk     AS date_key,
        'store'         AS channel,
        ss.ss_store_sk  AS store_or_site_id,
        SUM(ss.ss_net_paid)   AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_holiday = 'Y'
    GROUP BY d.d_date, d.d_date_sk, ss.ss_store_sk
),
web_agg AS (
    SELECT
        d.d_date               AS sales_date,
        d.d_date_sk            AS date_key,
        'web'                  AS channel,
        ws.ws_web_site_sk      AS store_or_site_id,
        SUM(ws.ws_net_paid)    AS total_net_paid,
        SUM(ws.ws_net_profit)  AS total_net_profit
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE wsite.web_class = 'Unknown'
    GROUP BY d.d_date, d.d_date_sk, ws.ws_web_site_sk
)
SELECT
    u.sales_date,
    u.channel,
    u.total_net_paid,
    u.total_net_profit,
    u.store_or_site_id,
    inv_stats.total_inventory
FROM (
    SELECT sales_date, date_key, channel, total_net_paid, total_net_profit, store_or_site_id
    FROM store_agg
    UNION ALL
    SELECT sales_date, date_key, channel, total_net_paid, total_net_profit, store_or_site_id
    FROM web_agg
) u
CROSS JOIN LATERAL (
    SELECT SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM inventory inv
    WHERE inv.inv_date_sk = u.date_key
) inv_stats
WHERE EXISTS (
    SELECT 1
    FROM inventory inv2
    WHERE inv2.inv_date_sk = u.date_key
      AND inv2.inv_quantity_on_hand > 0
)
ORDER BY u.sales_date DESC, u.channel
LIMIT 100
