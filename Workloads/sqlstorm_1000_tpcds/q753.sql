WITH date_range AS (
    SELECT d_date_sk, d_date
    FROM date_dim
    WHERE d_year BETWEEN 1999 AND 2001
), 
sales_union AS (
    SELECT 
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_store_sk AS store_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        CAST('store' AS varchar) AS channel,
        ss.ss_ticket_number AS ticket_number
    FROM store_sales ss
    JOIN date_range dr ON ss.ss_sold_date_sk = dr.d_date_sk

    UNION ALL

    SELECT 
        cs.cs_sold_date_sk,
        cs.cs_call_center_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid_inc_tax,
        cs.cs_net_profit,
        CAST('catalog' AS varchar),
        cs.cs_order_number
    FROM catalog_sales cs
    JOIN date_range dr ON cs.cs_sold_date_sk = dr.d_date_sk

    UNION ALL

    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_ship_mode_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        CAST('web' AS varchar),
        ws.ws_order_number
    FROM web_sales ws
    JOIN date_range dr ON ws.ws_sold_date_sk = dr.d_date_sk
), 
channel_agg AS (
    SELECT
        date_sk,
        store_sk,
        channel,
        SUM(net_profit) AS total_profit,
        SUM(net_paid) AS total_paid,
        COUNT(*) AS txn_count
    FROM sales_union
    GROUP BY date_sk, store_sk, channel
), 
store_moving_avg AS (
    SELECT
        ca.date_sk,
        ca.store_sk,
        ca.channel,
        ca.total_profit,
        AVG(ca.total_profit) OVER (
            PARTITION BY ca.store_sk 
            ORDER BY ca.date_sk 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS profit_7d_avg,
        CASE 
            WHEN ca.total_profit > AVG(ca.total_profit) OVER (
                PARTITION BY ca.store_sk 
                ORDER BY ca.date_sk 
                ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
            ) THEN CAST('above' AS varchar)
            ELSE CAST('below' AS varchar)
        END AS profit_vs_avg
    FROM channel_agg ca
), 
non_null_stores AS (
    SELECT *
    FROM store_moving_avg
    WHERE COALESCE(total_profit, 0) <> 0
), 
profit_anomalies AS (
    SELECT
        n.store_sk,
        n.channel,
        n.date_sk,
        n.total_profit,
        n.profit_7d_avg,
        n.profit_vs_avg,
        (
            SELECT MAX(ss2.ss_net_profit) 
            FROM store_sales ss2 
            WHERE ss2.ss_store_sk = n.store_sk 
              AND ss2.ss_sold_date_sk = n.date_sk
        ) AS max_store_profit,
        (
            SELECT MIN(cs2.cs_net_profit) 
            FROM catalog_sales cs2 
            WHERE cs2.cs_call_center_sk = n.store_sk 
              AND cs2.cs_sold_date_sk = n.date_sk
        ) AS min_catalog_profit
    FROM non_null_stores n
    WHERE n.total_profit > COALESCE(n.profit_7d_avg,0) * 2
       OR n.total_profit < COALESCE(n.profit_7d_avg,0) * 0.5
), 
store_profile AS (
    SELECT
        pa.store_sk,
        COALESCE(st.s_store_name, CAST('UNKNOWN' AS varchar)) AS store_name,
        COALESCE(st.s_city, CAST('UNKNOWN' AS varchar)) AS store_city,
        COALESCE(st.s_state, CAST('UNKNOWN' AS varchar)) AS store_state,
        COALESCE(st.s_gmt_offset, CAST(0 AS decimal(5,2))) AS gmt_offset,
        pa.channel,
        pa.date_sk,
        pa.total_profit,
        pa.profit_7d_avg,
        pa.profit_vs_avg,
        pa.max_store_profit,
        pa.min_catalog_profit,
        CONCAT('Store ', COALESCE(st.s_store_id,'0'), ' - ', CAST(pa.store_sk AS varchar)) AS store_label,
        CASE
            WHEN pa.max_store_profit IS NULL THEN CAST('No Store Sales' AS varchar)
            WHEN pa.min_catalog_profit IS NULL THEN CAST('No Catalog Sales' AS varchar)
            ELSE CAST('Both Present' AS varchar)
        END AS sales_coverage_flag,
        ROW_NUMBER() OVER (PARTITION BY pa.store_sk ORDER BY pa.total_profit DESC) AS profit_rank_overall
    FROM profit_anomalies pa
    LEFT JOIN store st ON pa.store_sk = st.s_store_sk
), 
cat_return_flag AS (
    SELECT
        cr.cr_catalog_page_sk AS store_sk,
        cr.cr_returned_date_sk AS date_sk,
        CAST('catalog_return' AS varchar) AS channel,
        SUM(cr.cr_net_loss) AS total_loss,
        COUNT(*) AS return_cnt,
        MAX(cr.cr_return_amount) AS max_return_amount
    FROM catalog_returns cr
    GROUP BY cr.cr_catalog_page_sk, cr.cr_returned_date_sk
), 
combined AS (
    SELECT
        sp.store_sk,
        sp.store_name,
        sp.store_city,
        sp.store_state,
        sp.gmt_offset,
        sp.channel,
        sp.date_sk,
        sp.total_profit,
        sp.profit_7d_avg,
        sp.profit_vs_avg,
        sp.max_store_profit,
        sp.min_catalog_profit,
        sp.store_label,
        sp.sales_coverage_flag,
        sp.profit_rank_overall
    FROM store_profile sp

    UNION ALL

    SELECT
        crf.store_sk,
        CAST(NULL AS varchar) AS store_name,
        CAST(NULL AS varchar) AS store_city,
        CAST(NULL AS varchar) AS store_state,
        CAST(0 AS decimal(5,2)) AS gmt_offset,
        crf.channel,
        crf.date_sk,
        -crf.total_loss AS total_profit,
        CAST(NULL AS decimal(7,2)) AS profit_7d_avg,
        CAST('return' AS varchar) AS profit_vs_avg,
        CAST(NULL AS decimal(7,2)) AS max_store_profit,
        CAST(NULL AS decimal(7,2)) AS min_catalog_profit,
        CONCAT('Return ', CAST(crf.store_sk AS varchar), '-', CAST(crf.date_sk AS varchar)) AS store_label,
        CAST('Return Data' AS varchar) AS sales_coverage_flag,
        ROW_NUMBER() OVER (PARTITION BY crf.store_sk ORDER BY crf.total_loss DESC) AS profit_rank_overall
    FROM cat_return_flag crf
)
SELECT *
FROM combined
WHERE profit_vs_avg = CAST('above' AS varchar)
   OR sales_coverage_flag = CAST('Return Data' AS varchar)
   OR store_label LIKE '%Store%'
ORDER BY profit_rank_overall
LIMIT 100
