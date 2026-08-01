/* Goal: Compare total net sales revenue and total return revenue per store, broken down by metric type, and rank stores by the amount. */
WITH sales_by_store AS (
    SELECT
        s.s_store_name AS store_name,
        COALESCE(ss_agg.total_net_paid, 0) AS total_net_paid,
        COALESCE(ss_agg.sales_cnt, 0) AS sales_cnt
    FROM store s
    LEFT JOIN LATERAL (
        SELECT
            SUM(ss.ss_net_paid) AS total_net_paid,
            COUNT(*) AS sales_cnt
        FROM store_sales ss
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        WHERE ss.ss_store_sk = s.s_store_sk
          AND ss.ss_quantity > 5
          AND cd.cd_gender = 'M'
          AND cd.cd_education_status = 'College'
    ) ss_agg ON TRUE
),
returns_by_store AS (
    SELECT
        s.s_store_name AS store_name,
        COALESCE(sr_agg.total_return_amt_inc_tax, 0) AS total_return_amt_inc_tax,
        COALESCE(sr_agg.returns_cnt, 0) AS returns_cnt
    FROM store s
    LEFT JOIN LATERAL (
        SELECT
            SUM(sr.sr_return_amt_inc_tax) AS total_return_amt_inc_tax,
            COUNT(*) AS returns_cnt
        FROM store_returns sr
        JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
        WHERE sr.sr_store_sk = s.s_store_sk
          AND sr.sr_return_quantity > 2
          AND cd.cd_marital_status = 'M'
    ) sr_agg ON TRUE
)
SELECT
    store_name,
    metric_type,
    amount,
    transaction_count
FROM (
    SELECT
        store_name,
        'sales' AS metric_type,
        total_net_paid AS amount,
        sales_cnt AS transaction_count
    FROM sales_by_store
    UNION ALL
    SELECT
        store_name,
        'returns' AS metric_type,
        total_return_amt_inc_tax AS amount,
        returns_cnt AS transaction_count
    FROM returns_by_store
) combined
ORDER BY amount DESC
LIMIT 100
