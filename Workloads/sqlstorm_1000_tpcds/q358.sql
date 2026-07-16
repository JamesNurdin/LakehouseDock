WITH
store_sales_agg AS (
    SELECT
        ss.ss_store_sk AS entity_sk,
        d.d_date,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(*) AS txn_count,
        SUM(ss.ss_ext_discount_amt + ss.ss_coupon_amt) AS total_discount,
        MAX(ss.ss_quantity) AS max_quantity,
        MIN(ss.ss_quantity) AS min_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss.ss_store_sk, d.d_date
),
web_sales_agg AS (
    SELECT
        ws.ws_web_page_sk AS entity_sk,
        d.d_date,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS txn_count,
        SUM(ws.ws_ext_discount_amt + ws.ws_coupon_amt) AS total_discount
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws.ws_web_page_sk, d.d_date
),
catalog_sales_agg AS (
    SELECT
        cs.cs_catalog_page_sk AS entity_sk,
        d.d_date,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS txn_count,
        SUM(cs.cs_ext_discount_amt + cs.cs_coupon_amt) AS total_discount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY cs.cs_catalog_page_sk, d.d_date
),
combined_sales AS (
    SELECT
        'store' AS channel,
        entity_sk,
        d_date,
        total_net_profit,
        total_sales,
        txn_count,
        total_discount
    FROM store_sales_agg
    UNION ALL
    SELECT
        'web' AS channel,
        entity_sk,
        d_date,
        total_net_profit,
        total_sales,
        txn_count,
        total_discount
    FROM web_sales_agg
    UNION ALL
    SELECT
        'catalog' AS channel,
        entity_sk,
        d_date,
        total_net_profit,
        total_sales,
        txn_count,
        total_discount
    FROM catalog_sales_agg
),
ranked_sales AS (
    SELECT
        channel,
        entity_sk,
        d_date,
        total_net_profit,
        total_sales,
        txn_count,
        total_discount,
        ROW_NUMBER() OVER (PARTITION BY channel, d_date ORDER BY total_net_profit DESC) AS profit_rank,
        SUM(total_sales) OVER (PARTITION BY channel ORDER BY d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales
    FROM combined_sales
)
SELECT
    rs.channel,
    rs.entity_sk,
    d.d_month_seq,
    rs.d_date,
    rs.total_net_profit,
    rs.total_sales,
    rs.txn_count,
    rs.total_discount,
    rs.profit_rank,
    rs.cumulative_sales,
    COALESCE(s.s_store_name, wp.wp_url, cp.cp_description) AS entity_name,
    LENGTH(COALESCE(s.s_store_name, wp.wp_url, cp.cp_description)) AS entity_name_len,
    CASE WHEN rs.total_discount IS NULL THEN 0 ELSE rs.total_discount END AS discount_amount,
    CONCAT('Rank_', CAST(rs.profit_rank AS VARCHAR)) AS rank_label,
    (SELECT cs3.total_net_profit FROM combined_sales cs3 WHERE cs3.channel = rs.channel AND cs3.entity_sk = rs.entity_sk AND cs3.d_date = date_add('day', -1, rs.d_date)) AS prior_day_profit,
    (SELECT COUNT(*) FROM combined_sales cs4 WHERE cs4.channel = rs.channel AND cs4.entity_sk = rs.entity_sk AND cs4.d_date BETWEEN date_add('day', -7, rs.d_date) AND rs.d_date) AS last_7_days_txns
FROM ranked_sales rs
LEFT JOIN store s ON rs.channel = 'store' AND rs.entity_sk = s.s_store_sk
LEFT JOIN web_page wp ON rs.channel = 'web' AND rs.entity_sk = wp.wp_web_page_sk
LEFT JOIN catalog_page cp ON rs.channel = 'catalog' AND rs.entity_sk = cp.cp_catalog_page_sk
JOIN date_dim d ON rs.d_date = d.d_date
WHERE rs.profit_rank <= 10
  AND (s.s_city IS NOT NULL OR wp.wp_url IS NOT NULL OR cp.cp_department IS NOT NULL)
ORDER BY rs.channel, rs.d_date DESC, rs.profit_rank
