/*
Goal: Compare total net paid and sales volume across physical stores and web sites for a specific date range, rank each channel by net revenue, flag high‑volume periods, and indicate whether the channel’s revenue is above the overall average.
*/
WITH
store_agg AS (
    SELECT
        'store' AS channel,
        ss.ss_store_sk AS channel_id,
        ss.ss_sold_date_sk AS date_sk,
        i.i_category AS product_category,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS total_net_loss,
        MAX(p.p_promo_name) AS promo_name,
        CASE WHEN SUM(ss.ss_quantity) > 100 THEN 'High' ELSE 'Low' END AS volume_level
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2451075 AND 2451085
      AND s.s_state = 'CA'
      AND p.p_channel_catalog = 'N'
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk, i.i_category
),
web_agg AS (
    SELECT
        'web' AS channel,
        ws.ws_web_site_sk AS channel_id,
        ws.ws_sold_date_sk AS date_sk,
        i.i_category AS product_category,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        0.0 AS total_net_loss,
        MAX(p.p_promo_name) AS promo_name,
        CASE WHEN SUM(ws.ws_quantity) > 100 THEN 'High' ELSE 'Low' END AS volume_level
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451075 AND 2451085
      AND w.web_state = 'CA'
      AND p.p_channel_catalog = 'N'
    GROUP BY ws.ws_web_site_sk, ws.ws_sold_date_sk, i.i_category
),
combined AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
),
avg_net AS (
    SELECT AVG(total_net_paid) AS avg_total_net FROM combined
)
SELECT
    channel,
    channel_id,
    date_sk,
    product_category,
    total_quantity,
    total_net_paid,
    total_net_loss,
    promo_name,
    volume_level,
    RANK() OVER (PARTITION BY channel ORDER BY total_net_paid DESC) AS net_paid_rank,
    CASE WHEN total_net_paid > (SELECT avg_total_net FROM avg_net)
         THEN 'Above Avg' ELSE 'Below Avg' END AS avg_comparison
FROM combined
WHERE total_quantity > 0
ORDER BY channel, net_paid_rank
LIMIT 100
