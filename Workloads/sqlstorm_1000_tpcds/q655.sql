WITH union_sales AS (
    SELECT ss_sold_date_sk AS sale_date_sk,
           ss_item_sk AS item_sk,
           ss_store_sk AS store_sk,
           CAST(NULL AS integer) AS catalog_page_sk,
           CAST(NULL AS integer) AS call_center_sk,
           'store' AS channel,
           ss_quantity AS quantity,
           ss_net_paid AS net_paid,
           ss_net_profit AS net_profit
    FROM store_sales
    UNION ALL
    SELECT cs_sold_date_sk,
           cs_item_sk,
           CAST(NULL AS integer),
           cs_catalog_page_sk,
           cs_call_center_sk,
           'catalog',
           cs_quantity,
           cs_net_paid,
           cs_net_profit
    FROM catalog_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_item_sk,
           CAST(NULL AS integer),
           CAST(NULL AS integer),
           CAST(NULL AS integer),
           'web',
           ws_quantity,
           ws_net_paid,
           ws_net_profit
    FROM web_sales
),
agg_daily AS (
    SELECT
        d.d_date,
        s.channel,
        COALESCE(s.store_sk, -1) AS store_sk,
        COALESCE(s.catalog_page_sk, -1) AS catalog_page_sk,
        COALESCE(s.call_center_sk, -1) AS call_center_sk,
        SUM(s.quantity) AS total_quantity,
        SUM(s.net_paid) AS total_net_paid,
        SUM(s.net_profit) AS total_net_profit,
        COUNT(DISTINCT s.item_sk) AS distinct_items,
        CASE WHEN SUM(s.net_paid) = 0 THEN NULL ELSE SUM(s.net_profit) / SUM(s.net_paid) END AS profit_paid_ratio
    FROM union_sales s
    JOIN date_dim d ON s.sale_date_sk = d.d_date_sk
    GROUP BY d.d_date, s.channel, COALESCE(s.store_sk, -1), COALESCE(s.catalog_page_sk, -1), COALESCE(s.call_center_sk, -1)
),
top_items AS (
    SELECT
        d.d_date,
        s.channel,
        s.item_sk,
        SUM(s.net_profit) AS item_net_profit,
        ROW_NUMBER() OVER (PARTITION BY d.d_date, s.channel ORDER BY SUM(s.net_profit) DESC) AS rn
    FROM union_sales s
    JOIN date_dim d ON s.sale_date_sk = d.d_date_sk
    GROUP BY d.d_date, s.channel, s.item_sk
),
store_info AS (
    SELECT s_store_sk, s_store_name FROM store
),
call_center_info AS (
    SELECT cc_call_center_sk, cc_name FROM call_center
),
daily_with_details AS (
    SELECT
        a.d_date,
        a.channel,
        a.store_sk,
        COALESCE(st.s_store_name, 'N/A') AS store_name,
        COALESCE(cc.cc_name, 'No Call Center') AS call_center_name,
        a.total_quantity,
        a.total_net_paid,
        a.total_net_profit,
        a.profit_paid_ratio,
        LAG(a.total_net_profit) OVER (PARTITION BY a.channel, a.store_sk ORDER BY a.d_date) AS prev_day_profit,
        a.total_net_profit - LAG(a.total_net_profit) OVER (PARTITION BY a.channel, a.store_sk ORDER BY a.d_date) AS profit_change_vs_prev_day,
        CASE
            WHEN LAG(a.total_net_profit) OVER (PARTITION BY a.channel, a.store_sk ORDER BY a.d_date) = 0 THEN NULL
            ELSE (a.total_net_profit - LAG(a.total_net_profit) OVER (PARTITION BY a.channel, a.store_sk ORDER BY a.d_date)) / LAG(a.total_net_profit) OVER (PARTITION BY a.channel, a.store_sk ORDER BY a.d_date)
        END AS profit_change_pct,
        SUM(a.total_net_profit) OVER (PARTITION BY a.channel, a.store_sk ORDER BY a.d_date ROWS UNBOUNDED PRECEDING) AS cumulative_profit,
        AVG(a.total_net_profit) OVER (PARTITION BY a.channel, a.store_sk ORDER BY a.d_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS avg_7d_profit,
        (SELECT SUM(total_net_profit) FROM agg_daily a2 WHERE a2.d_date = a.d_date AND a2.channel = a.channel) AS channel_total_profit,
        CASE
            WHEN (SELECT SUM(total_net_profit) FROM agg_daily a2 WHERE a2.d_date = a.d_date AND a2.channel = a.channel) = 0 THEN NULL
            ELSE a.total_net_profit / (SELECT SUM(total_net_profit) FROM agg_daily a2 WHERE a2.d_date = a.d_date AND a2.channel = a.channel)
        END AS profit_share_of_channel,
        CONCAT(UPPER(a.channel), '_', format_datetime(CAST(a.d_date AS timestamp), 'yyyyMMdd')) AS channel_date_key,
        COALESCE(
            (SELECT array_join(array_agg(CONCAT('Item', CAST(t.item_sk AS VARCHAR), ':', CAST(t.item_net_profit AS VARCHAR))), ',')
             FROM top_items t
             WHERE t.d_date = a.d_date AND t.channel = a.channel AND t.rn <= 5),
            ''
        ) AS top_items_snapshot
    FROM agg_daily a
    LEFT JOIN store_info st ON a.store_sk = st.s_store_sk
    LEFT JOIN call_center_info cc ON a.call_center_sk = cc.cc_call_center_sk
)
SELECT *
FROM daily_with_details
