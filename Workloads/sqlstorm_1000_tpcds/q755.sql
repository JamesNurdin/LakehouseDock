WITH date_filter AS (
    SELECT d_date_sk,
           d_date,
           d_year,
           d_month_seq,
           d_day_name,
           d_week_seq
    FROM date_dim
    WHERE d_year BETWEEN 2000 AND 2002
),
store_sales_agg AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        ss.ss_sold_date_sk AS date_sk,
        SUM(ss.ss_net_profit) AS net_profit,
        SUM(ss.ss_net_paid) AS net_paid,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN date_filter df ON ss.ss_sold_date_sk = df.d_date_sk
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk
),
catalog_sales_agg AS (
    SELECT
        cs.cs_call_center_sk AS cc_sk,
        cs.cs_sold_date_sk AS date_sk,
        SUM(cs.cs_net_profit) AS net_profit,
        SUM(cs.cs_net_paid) AS net_paid,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN date_filter df ON cs.cs_sold_date_sk = df.d_date_sk
    GROUP BY cs.cs_call_center_sk, cs.cs_sold_date_sk
),
web_sales_agg AS (
    SELECT
        ws.ws_web_page_sk AS wp_sk,
        ws.ws_sold_date_sk AS date_sk,
        SUM(ws.ws_net_profit) AS net_profit,
        SUM(ws.ws_net_paid) AS net_paid,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN date_filter df ON ws.ws_sold_date_sk = df.d_date_sk
    GROUP BY ws.ws_web_page_sk, ws.ws_sold_date_sk
),
combined_sales AS (
    SELECT
        'store' AS sales_type,
        ss.store_sk AS entity_sk,
        ss.date_sk,
        ss.net_profit,
        ss.net_paid,
        ss.sales_cnt
    FROM store_sales_agg ss
    UNION ALL
    SELECT
        'call_center' AS sales_type,
        cc.cc_sk AS entity_sk,
        cc.date_sk,
        cc.net_profit,
        cc.net_paid,
        cc.sales_cnt
    FROM catalog_sales_agg cc
    UNION ALL
    SELECT
        'web' AS sales_type,
        wp.wp_sk AS entity_sk,
        wp.date_sk,
        wp.net_profit,
        wp.net_paid,
        wp.sales_cnt
    FROM web_sales_agg wp
),
sales_with_dates AS (
    SELECT
        cs.sales_type,
        cs.entity_sk,
        cs.date_sk,
        cs.net_profit,
        cs.net_paid,
        cs.sales_cnt,
        df.d_date,
        df.d_year,
        df.d_month_seq,
        df.d_day_name,
        df.d_week_seq
    FROM combined_sales cs
    LEFT JOIN date_filter df ON cs.date_sk = df.d_date_sk
),
store_dim AS (
    SELECT
        s.s_store_sk,
        CONCAT(s.s_store_name, ' - ', s.s_city) AS label,
        s.s_state,
        s.s_country,
        s.s_gmt_offset
    FROM store s
),
call_center_dim AS (
    SELECT
        cc.cc_call_center_sk,
        CONCAT(cc.cc_name, ' (', cc.cc_city, ')') AS label,
        cc.cc_state,
        cc.cc_country,
        cc.cc_gmt_offset
    FROM call_center cc
),
web_page_dim AS (
    SELECT
        wp.wp_web_page_sk,
        CONCAT(wp.wp_type, ':', wp.wp_url) AS label,
        NULL AS state,
        NULL AS country,
        NULL AS gmt_offset
    FROM web_page wp
),
final_metrics AS (
    SELECT
        swd.sales_type,
        swd.d_date,
        CASE
            WHEN swd.sales_type = 'store' THEN sd.label
            WHEN swd.sales_type = 'call_center' THEN ccd.label
            WHEN swd.sales_type = 'web' THEN wpd.label
            ELSE 'UNKNOWN'
        END AS entity_label,
        COALESCE(swd.net_profit, 0) AS net_profit,
        COALESCE(swd.net_paid, 0) AS net_paid,
        swd.sales_cnt,
        COALESCE(
            CASE
                WHEN swd.sales_type = 'store' THEN sd.s_state
                WHEN swd.sales_type = 'call_center' THEN ccd.cc_state
                ELSE NULL
            END,
            'N/A'
        ) AS state,
        SUM(COALESCE(swd.net_profit, 0)) OVER (
            PARTITION BY swd.sales_type, swd.entity_sk
            ORDER BY swd.d_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS net_profit_7day_sum,
        SUM(COALESCE(swd.net_profit, 0)) OVER (
            PARTITION BY swd.sales_type, swd.entity_sk
        ) AS total_entity_net_profit,
        (
            SELECT COALESCE(SUM(swd_prev.net_profit), 0)
            FROM sales_with_dates swd_prev
            WHERE swd_prev.sales_type = swd.sales_type
              AND swd_prev.entity_sk = swd.entity_sk
              AND swd_prev.d_date = DATE_ADD('year', -1, swd.d_date)
        ) AS prior_year_net_profit,
        CASE
            WHEN COALESCE(swd.net_profit, 0) < 0 THEN 'LOSS'
            WHEN COALESCE(swd.net_profit, 0) BETWEEN 0 AND 1000 THEN 'LOW'
            WHEN COALESCE(swd.net_profit, 0) BETWEEN 1000 AND 10000 THEN 'MEDIUM'
            ELSE 'HIGH'
        END AS profit_category,
        SUBSTR(UPPER(
            CASE
                WHEN swd.sales_type = 'store' THEN sd.label
                WHEN swd.sales_type = 'call_center' THEN ccd.label
                WHEN swd.sales_type = 'web' THEN wpd.label
                ELSE 'UNKNOWN'
            END
        ), 1, 3) AS label_prefix
    FROM sales_with_dates swd
    LEFT JOIN store_dim sd ON swd.sales_type = 'store' AND sd.s_store_sk = swd.entity_sk
    LEFT JOIN call_center_dim ccd ON swd.sales_type = 'call_center' AND ccd.cc_call_center_sk = swd.entity_sk
    LEFT JOIN web_page_dim wpd ON swd.sales_type = 'web' AND wpd.wp_web_page_sk = swd.entity_sk
)
SELECT
    fm.sales_type,
    fm.d_date,
    fm.entity_label,
    fm.net_profit,
    fm.net_paid,
    fm.sales_cnt,
    fm.state,
    fm.net_profit_7day_sum,
    fm.prior_year_net_profit,
    fm.profit_category,
    fm.label_prefix,
    DENSE_RANK() OVER (PARTITION BY fm.state ORDER BY fm.total_entity_net_profit DESC) AS profit_rank_state
FROM final_metrics fm
WHERE fm.net_profit_7day_sum IS NOT NULL
ORDER BY fm.d_date DESC, fm.net_profit_7day_sum DESC
LIMIT 200
