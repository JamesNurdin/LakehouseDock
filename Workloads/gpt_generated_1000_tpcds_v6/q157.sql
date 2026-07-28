/*
 * Goal: Compare item‑level sales performance during peak midday hours (12‑14) across the brick‑and‑mortar store channel and the web channel.
 * The query aggregates quantity sold and net paid amount per item for each channel, then combines the two result sets with UNION ALL.
 */
WITH store_agg AS (
    SELECT
        i.i_item_id,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_revenue,
        CAST('store' AS varchar) AS channel
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 12 AND 14
    GROUP BY i.i_item_id
),
web_agg AS (
    SELECT
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_revenue,
        CAST('web' AS varchar) AS channel
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 12 AND 14
    GROUP BY i.i_item_id
)
SELECT *
FROM store_agg
UNION ALL
SELECT *
FROM web_agg
ORDER BY total_quantity DESC
LIMIT 100
