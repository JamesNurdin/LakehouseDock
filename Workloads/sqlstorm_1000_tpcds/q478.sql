WITH
date_series AS (
    SELECT d_date_sk
    FROM UNNEST(
        sequence(
            (SELECT MIN(d_date_sk) FROM date_dim),
            (SELECT MAX(d_date_sk) FROM date_dim)
        )
    ) AS t(d_date_sk)
),
catalog_daily_agg AS (
    SELECT
        cs.cs_sold_date_sk AS d_date_sk,
        COALESCE(cc.cc_name, 'UNKNOWN') AS entity_name,
        SUM(cs.cs_net_paid) AS net_paid,
        SUM(cs.cs_net_profit) AS net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS orders,
        SUM(cs.cs_quantity) AS quantity,
        SUM(cs.cs_ext_discount_amt) AS discount,
        CASE WHEN SUM(cs.cs_net_paid) = 0 THEN NULL ELSE SUM(cs.cs_net_profit) / SUM(cs.cs_net_paid) END AS profit_ratio
    FROM catalog_sales cs
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    GROUP BY cs.cs_sold_date_sk, cc.cc_name
),
store_daily_agg AS (
    SELECT
        ss.ss_sold_date_sk AS d_date_sk,
        COALESCE(s.s_store_name, 'UNKNOWN') AS entity_name,
        SUM(ss.ss_net_paid) AS net_paid,
        SUM(ss.ss_net_profit) AS net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS orders,
        SUM(ss.ss_quantity) AS quantity,
        SUM(ss.ss_ext_discount_amt) AS discount,
        CASE WHEN SUM(ss.ss_net_paid) = 0 THEN NULL ELSE SUM(ss.ss_net_profit) / SUM(ss.ss_net_paid) END AS profit_ratio
    FROM store_sales ss
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY ss.ss_sold_date_sk, s.s_store_name
),
web_daily_agg AS (
    SELECT
        ws.ws_sold_date_sk AS d_date_sk,
        COALESCE(wp.wp_url, 'UNKNOWN') AS entity_name,
        SUM(ws.ws_net_paid) AS net_paid,
        SUM(ws.ws_net_profit) AS net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS orders,
        SUM(ws.ws_quantity) AS quantity,
        SUM(ws.ws_ext_discount_amt) AS discount,
        CASE WHEN SUM(ws.ws_net_paid) = 0 THEN NULL ELSE SUM(ws.ws_net_profit) / SUM(ws.ws_net_paid) END AS profit_ratio
    FROM web_sales ws
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    GROUP BY ws.ws_sold_date_sk, wp.wp_url
),
all_sales AS (
    SELECT d_date_sk, 'Catalog' AS channel, entity_name, net_paid, net_profit, orders, quantity, discount, profit_ratio
    FROM catalog_daily_agg
    UNION ALL
    SELECT d_date_sk, 'Store' AS channel, entity_name, net_paid, net_profit, orders, quantity, discount, profit_ratio
    FROM store_daily_agg
    UNION ALL
    SELECT d_date_sk, 'Web' AS channel, entity_name, net_paid, net_profit, orders, quantity, discount, profit_ratio
    FROM web_daily_agg
),
positive_dates AS (
    SELECT DISTINCT d_date_sk FROM all_sales WHERE net_profit > 0
),
high_profit_dates AS (
    SELECT DISTINCT d_date_sk FROM all_sales WHERE net_profit > 10000
),
common_dates AS (
    SELECT d_date_sk FROM positive_dates INTERSECT SELECT d_date_sk FROM high_profit_dates
),
ranked_sales AS (
    SELECT
        d_date_sk,
        channel,
        entity_name,
        net_paid,
        net_profit,
        orders,
        quantity,
        discount,
        profit_ratio,
        ROW_NUMBER() OVER (PARTITION BY d_date_sk ORDER BY net_profit DESC) AS profit_rank,
        CASE WHEN entity_name IS NULL THEN 'UNKNOWN' ELSE entity_name END AS entity_name_coalesced
    FROM all_sales
),
final AS (
    SELECT
        d.d_date,
        d.d_year,
        d.d_month_seq,
        r.channel,
        r.entity_name_coalesced AS entity_name,
        r.net_paid,
        r.net_profit,
        r.orders,
        r.quantity,
        r.discount,
        r.profit_ratio,
        r.profit_rank,
        COALESCE(r.profit_ratio, 0) AS profit_ratio_coalesced,
        CONCAT(r.channel, ':', COALESCE(r.entity_name, 'UNKNOWN')) AS channel_entity,
        CASE
            WHEN r.net_profit > 0 THEN 'POSITIVE'
            WHEN r.net_profit < 0 THEN 'NEGATIVE'
            ELSE 'ZERO'
        END AS profit_sign,
        (SELECT AVG(a2.net_profit) FROM all_sales a2 WHERE a2.channel = r.channel) AS avg_channel_net_profit,
        (SELECT AVG(a3.net_profit) FROM all_sales a3 WHERE a3.d_date_sk = r.d_date_sk) AS avg_day_net_profit
    FROM date_series ds
    INNER JOIN common_dates cd ON ds.d_date_sk = cd.d_date_sk
    LEFT JOIN date_dim d ON ds.d_date_sk = d.d_date_sk
    LEFT JOIN ranked_sales r ON ds.d_date_sk = r.d_date_sk
    WHERE r.profit_rank <= 3
)
SELECT *
FROM final
ORDER BY d_date DESC, profit_rank
