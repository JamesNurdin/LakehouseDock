WITH
date_key AS (
    SELECT d_date_sk, d_year, d_month_seq
    FROM date_dim
    WHERE d_year BETWEEN 1998 AND 2001
),
store_agg AS (
    SELECT
        s.s_store_id AS entity_id,
        s.s_store_name AS entity_name,
        CONCAT(s.s_store_name, ' (', COALESCE(s.s_city, ''), ', ', COALESCE(s.s_state, ''), ')') AS entity_label,
        'store' AS entity_type,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_item_sk) AS distinct_items,
        COALESCE(p.p_promo_name, 'NoPromo') AS promo_name,
        COUNT(*) AS transaction_count
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_key d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE s.s_state IS NOT NULL
    GROUP BY s.s_store_id, s.s_store_name, s.s_city, s.s_state,
             d.d_year, d.d_month_seq,
             p.p_promo_name
),
web_agg AS (
    SELECT
        ws.web_site_id AS entity_id,
        ws.web_name AS entity_name,
        CONCAT(ws.web_name, ' (', COALESCE(ws.web_city, ''), ', ', COALESCE(ws.web_state, ''), ')') AS entity_label,
        'web' AS entity_type,
        d.d_year,
        d.d_month_seq,
        SUM(wss.ws_net_paid) AS total_net_paid,
        SUM(wss.ws_net_profit) AS total_profit,
        SUM(wss.ws_quantity) AS total_quantity,
        COUNT(DISTINCT wss.ws_item_sk) AS distinct_items,
        COALESCE(p.p_promo_name, 'NoPromo') AS promo_name,
        COUNT(*) AS transaction_count
    FROM web_sales wss
    JOIN web_site ws ON wss.ws_web_site_sk = ws.web_site_sk
    JOIN date_key d ON wss.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON wss.ws_promo_sk = p.p_promo_sk
    LEFT JOIN item i ON wss.ws_item_sk = i.i_item_sk
    LEFT JOIN customer c ON wss.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.web_state IS NOT NULL
    GROUP BY ws.web_site_id, ws.web_name, ws.web_city, ws.web_state,
             d.d_year, d.d_month_seq,
             p.p_promo_name
),
catalog_agg AS (
    SELECT
        cc.cc_call_center_id AS entity_id,
        cc.cc_name AS entity_name,
        CONCAT(cc.cc_name, ' (', COALESCE(cc.cc_city, ''), ', ', COALESCE(cc.cc_state, ''), ')') AS entity_label,
        'catalog' AS entity_type,
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs.cs_item_sk) AS distinct_items,
        COALESCE(p.p_promo_name, 'NoPromo') AS promo_name,
        COUNT(*) AS transaction_count
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_key d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cc.cc_state IS NOT NULL
    GROUP BY cc.cc_call_center_id, cc.cc_name, cc.cc_city, cc.cc_state,
             d.d_year, d.d_month_seq,
             p.p_promo_name
),
combined_agg AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
    UNION ALL
    SELECT * FROM catalog_agg
),
ranked_agg AS (
    SELECT
        ca.*,
        RANK() OVER (PARTITION BY ca.entity_type, ca.d_year, ca.d_month_seq ORDER BY ca.total_profit DESC) AS profit_rank,
        LAG(ca.total_profit) OVER (PARTITION BY ca.entity_type, ca.entity_id ORDER BY ca.d_year, ca.d_month_seq) AS prev_month_profit,
        COALESCE(ca.total_quantity, 0) AS qty_nonnull
    FROM combined_agg ca
),
final AS (
    SELECT
        ra.entity_id,
        ra.entity_name,
        ra.entity_label,
        ra.entity_type,
        ra.d_year,
        ra.d_month_seq,
        ra.total_net_paid,
        ra.total_profit,
        ra.total_quantity,
        ra.distinct_items,
        ra.promo_name,
        ra.transaction_count,
        ra.profit_rank,
        ra.prev_month_profit,
        CASE
            WHEN ra.prev_month_profit IS NULL THEN NULL
            WHEN ra.total_profit > ra.prev_month_profit THEN 'UP'
            WHEN ra.total_profit < ra.prev_month_profit THEN 'DOWN'
            ELSE 'FLAT'
        END AS profit_trend,
        (SELECT AVG(ca2.total_profit)
         FROM combined_agg ca2
         WHERE ca2.entity_type = ra.entity_type
           AND ca2.d_year = ra.d_year - 1
           AND ca2.d_month_seq = ra.d_month_seq) AS prev_year_avg_profit,
        CASE
            WHEN ra.total_profit > 0 AND ra.distinct_items > 5 AND ra.promo_name <> 'NoPromo' THEN 1
            ELSE 0
        END AS high_perf_flag
    FROM ranked_agg ra
    WHERE
        (ra.entity_label LIKE '%New%' OR ra.entity_label LIKE '%York%')
        AND COALESCE(ra.total_quantity, 0) > 0
        AND ra.promo_name <> 'NoPromo'
        AND ((ra.entity_type = 'store' AND ra.total_profit > 1000)
             OR (ra.entity_type = 'web' AND ra.total_profit > 500)
             OR (ra.entity_type = 'catalog' AND ra.total_profit > 800))
)

SELECT
    entity_type,
    entity_id,
    entity_name,
    entity_label,
    d_year,
    d_month_seq,
    total_net_paid,
    total_profit,
    total_quantity,
    distinct_items,
    promo_name,
    transaction_count,
    profit_rank,
    profit_trend,
    prev_year_avg_profit,
    high_perf_flag,
    CONCAT(entity_name, ' (', entity_type, ') - Profit: ', CAST(total_profit AS VARCHAR)) AS report_line
FROM final
ORDER BY entity_type, d_year, d_month_seq, profit_rank
LIMIT 100
