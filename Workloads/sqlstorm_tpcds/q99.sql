WITH store_base AS (
    SELECT
        d.d_date,
        s.s_store_id AS identifier,
        s.s_state AS region,
        SUM(ss.ss_net_profit) AS net_profit,
        SUM(ss.ss_net_paid) AS net_paid,
        SUM(ss.ss_quantity) AS quantity,
        AVG(ss.ss_ext_discount_amt / nullif(ss.ss_ext_sales_price, 0)) AS avg_discount_rate,
        COUNT(DISTINCT ss.ss_item_sk) AS distinct_items_sold
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY d.d_date, s.s_store_id, s.s_state
),
store_agg AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY d_date ORDER BY net_profit DESC) AS date_rank
    FROM store_base
),
catalog_base AS (
    SELECT
        d.d_date,
        cc.cc_call_center_id AS identifier,
        cc.cc_state AS region,
        SUM(cs.cs_net_profit) AS net_profit,
        SUM(cs.cs_net_paid) AS net_paid,
        SUM(cs.cs_quantity) AS quantity,
        AVG(cs.cs_ext_discount_amt / nullif(cs.cs_ext_sales_price, 0)) AS avg_discount_rate,
        COUNT(DISTINCT cs.cs_item_sk) AS distinct_items_sold
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY d.d_date, cc.cc_call_center_id, cc.cc_state
),
catalog_agg AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY d_date ORDER BY net_profit DESC) AS date_rank
    FROM catalog_base
),
web_base AS (
    SELECT
        d.d_date,
        ws.ws_web_page_sk AS identifier,
        wp.wp_type AS region,
        SUM(ws.ws_net_profit) AS net_profit,
        SUM(ws.ws_net_paid) AS net_paid,
        SUM(ws.ws_quantity) AS quantity,
        AVG(ws.ws_ext_discount_amt / nullif(ws.ws_ext_sales_price, 0)) AS avg_discount_rate,
        COUNT(DISTINCT ws.ws_item_sk) AS distinct_items_sold
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY d.d_date, ws.ws_web_page_sk, wp.wp_type
),
web_agg AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY d_date ORDER BY net_profit DESC) AS date_rank
    FROM web_base
),
top_items_raw AS (
    SELECT
        d.d_date,
        f.channel,
        i.i_item_id,
        i.i_category,
        i.i_brand,
        SUM(f.net_profit) AS total_net_profit,
        SUM(f.quantity) AS total_quantity
    FROM (
        SELECT ss_sold_date_sk AS date_sk, ss_item_sk AS item_sk, ss_net_profit AS net_profit, ss_quantity AS quantity, 'store' AS channel
        FROM store_sales
        UNION ALL
        SELECT cs_sold_date_sk, cs_item_sk, cs_net_profit, cs_quantity, 'catalog'
        FROM catalog_sales
        UNION ALL
        SELECT ws_sold_date_sk, ws_item_sk, ws_net_profit, ws_quantity, 'web'
        FROM web_sales
    ) f
    JOIN date_dim d ON f.date_sk = d.d_date_sk
    JOIN item i ON f.item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY d.d_date, f.channel, i.i_item_id, i.i_category, i.i_brand
),
top_items_per_day AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY d_date, channel ORDER BY total_net_profit DESC) AS rn
    FROM top_items_raw
)
SELECT
    s.d_date,
    'store' AS channel,
    s.identifier,
    s.region,
    s.net_profit,
    s.net_paid,
    s.quantity,
    s.avg_discount_rate,
    s.distinct_items_sold,
    (SELECT array_agg(row(t.i_item_id, t.total_net_profit) ORDER BY t.total_net_profit DESC)
     FROM top_items_per_day t
     WHERE t.d_date = s.d_date AND t.channel = 'store' AND t.rn <= 3) AS top_items
FROM store_agg s
WHERE s.date_rank <= 5

UNION ALL

SELECT
    c.d_date,
    'catalog' AS channel,
    c.identifier,
    c.region,
    c.net_profit,
    c.net_paid,
    c.quantity,
    c.avg_discount_rate,
    c.distinct_items_sold,
    (SELECT array_agg(row(t.i_item_id, t.total_net_profit) ORDER BY t.total_net_profit DESC)
     FROM top_items_per_day t
     WHERE t.d_date = c.d_date AND t.channel = 'catalog' AND t.rn <= 3) AS top_items
FROM catalog_agg c
WHERE c.date_rank <= 5

UNION ALL

SELECT
    w.d_date,
    'web' AS channel,
    CAST(w.identifier AS VARCHAR) AS identifier,
    w.region,
    w.net_profit,
    w.net_paid,
    w.quantity,
    w.avg_discount_rate,
    w.distinct_items_sold,
    (SELECT array_agg(row(t.i_item_id, t.total_net_profit) ORDER BY t.total_net_profit DESC)
     FROM top_items_per_day t
     WHERE t.d_date = w.d_date AND t.channel = 'web' AND t.rn <= 3) AS top_items
FROM web_agg w
WHERE w.date_rank <= 5
ORDER BY d_date DESC, channel, identifier
