WITH
    store_info AS (
        SELECT s_store_sk, s_store_id
        FROM store
    ),
    promo_info AS (
        SELECT p_promo_sk, p_promo_name
        FROM promotion
    ),
    reason_info AS (
        SELECT r_reason_sk, r_reason_desc
        FROM reason
    ),
    sales_agg AS (
        SELECT
            si.s_store_id AS store_id,
            pi.p_promo_name AS descriptor,
            'Sales' AS metric_type,
            SUM(ss.ss_net_paid) AS sum_amount
        FROM store_sales ss
        JOIN store_info si ON ss.ss_store_sk = si.s_store_sk
        JOIN promo_info pi ON ss.ss_promo_sk = pi.p_promo_sk
        WHERE ss.ss_sold_date_sk BETWEEN 2450881 AND 2450881 + 30
        GROUP BY ROLLUP (si.s_store_id, pi.p_promo_name)
    ),
    returns_agg AS (
        SELECT
            si.s_store_id AS store_id,
            ri.r_reason_desc AS descriptor,
            'Returns' AS metric_type,
            SUM(sr.sr_net_loss) AS sum_amount
        FROM store_returns sr
        JOIN store_info si ON sr.sr_store_sk = si.s_store_sk
        JOIN reason_info ri ON sr.sr_reason_sk = ri.r_reason_sk
        WHERE sr.sr_returned_date_sk BETWEEN 2450881 AND 2450881 + 30
        GROUP BY ROLLUP (si.s_store_id, ri.r_reason_desc)
    ),
    union_data AS (
        SELECT * FROM sales_agg
        UNION ALL
        SELECT * FROM returns_agg
    )
SELECT
    COALESCE(store_id, 'ALL') AS store_id,
    descriptor,
    metric_type,
    sum_amount,
    CASE
        WHEN sum_amount > (SELECT AVG(ss_ext_sales_price) FROM store_sales) THEN 'High'
        ELSE 'Low'
    END AS amount_category,
    ROW_NUMBER() OVER (PARTITION BY COALESCE(store_id, 'ALL') ORDER BY sum_amount DESC) AS rank_within_store
FROM union_data
WHERE sum_amount IS NOT NULL
ORDER BY store_id, descriptor, metric_type
LIMIT 100
