WITH agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_category,
        SUM(sr.sr_return_quantity) AS total_return_quantity,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount_inc_tax,
        AVG(sr.sr_return_amt) AS avg_return_amount,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    WHERE s.s_state = 'CA'
    GROUP BY s.s_store_id, s.s_store_name, i.i_category
),
reason_counts AS (
    SELECT
        s.s_store_id,
        i.i_category,
        r.r_reason_desc,
        COUNT(*) AS reason_return_cnt
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE s.s_state = 'CA'
    GROUP BY s.s_store_id, i.i_category, r.r_reason_desc
),
top_reason AS (
    SELECT
        s_store_id,
        i_category,
        r_reason_desc,
        reason_return_cnt,
        ROW_NUMBER() OVER (PARTITION BY s_store_id, i_category ORDER BY reason_return_cnt DESC) AS rn
    FROM reason_counts
)
SELECT
    agg.s_store_id,
    agg.s_store_name,
    agg.i_category,
    agg.total_return_quantity,
    agg.total_return_amount,
    agg.total_return_amount_inc_tax,
    agg.avg_return_amount,
    agg.distinct_customers,
    tr.r_reason_desc AS top_return_reason,
    tr.reason_return_cnt AS top_reason_return_count
FROM agg
JOIN top_reason tr
    ON agg.s_store_id = tr.s_store_id
   AND agg.i_category = tr.i_category
WHERE tr.rn = 1
ORDER BY agg.total_return_amount DESC
LIMIT 100
