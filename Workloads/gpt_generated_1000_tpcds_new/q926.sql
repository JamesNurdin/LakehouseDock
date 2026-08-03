WITH
    agg_returns AS (
        SELECT
            cc.cc_call_center_sk,
            cc.cc_call_center_id,
            cc.cc_state,
            cc.cc_mkt_class,
            cc.cc_rec_start_date,
            SUM(cr.cr_return_amount) AS sum_return_amount,
            SUM(cr.cr_return_quantity) AS sum_return_qty,
            COUNT(*) AS cnt_returns
        FROM
            call_center cc
            JOIN catalog_returns cr
                ON cr.cr_call_center_sk = cc.cc_call_center_sk
        WHERE
            cc.cc_rec_start_date >= DATE '2000-01-01'
            AND cc.cc_rec_start_date <= DATE '2002-12-31'
            AND cc.cc_state IN ('CA', 'TX', 'NY')
            AND cc.cc_mkt_class LIKE '%Psychiatric%'
            AND cr.cr_returned_date_sk BETWEEN 1000 AND 2000
        GROUP BY
            cc.cc_call_center_sk,
            cc.cc_call_center_id,
            cc.cc_state,
            cc.cc_mkt_class,
            cc.cc_rec_start_date
    ),
    filtered_agg AS (
        SELECT
            *,
            CASE WHEN sum_return_amount > 1000 THEN 'HIGH' ELSE 'LOW' END AS amount_level
        FROM agg_returns
        WHERE sum_return_amount > 0
    ),
    intersect_ids AS (
        SELECT cc_call_center_id FROM call_center WHERE cc_state = 'CA'
        INTERSECT
        SELECT cc_call_center_id FROM call_center WHERE cc_state = 'TX'
    ),
    final_agg AS (
        SELECT
            fa.cc_call_center_id,
            fa.cc_state,
            fa.cc_mkt_class,
            fa.sum_return_amount,
            fa.sum_return_qty,
            fa.cnt_returns,
            fa.amount_level,
            ROW_NUMBER() OVER (PARTITION BY fa.cc_state ORDER BY fa.sum_return_amount DESC) AS rn_state,
            SUM(fa.sum_return_amount) OVER (
                PARTITION BY fa.cc_state
                ORDER BY fa.sum_return_amount DESC
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS running_state_sum
        FROM filtered_agg fa
        WHERE fa.cc_call_center_id NOT IN (
                SELECT cc_call_center_id FROM call_center WHERE cc_zip LIKE '9%'
            )
            AND fa.cc_call_center_id IN (SELECT cc_call_center_id FROM intersect_ids)
    )
SELECT
    t.cc_id,
    t.cc_state,
    t.cc_mkt_class,
    t.sum_return_amount,
    t.sum_return_qty,
    t.cnt_returns,
    t.amount_level,
    t.rn_state,
    t.running_state_sum,
    LAG(t.sum_return_amount) OVER (PARTITION BY t.cc_state ORDER BY t.sum_return_amount DESC) AS prev_sum_amount
FROM (
    SELECT
        cc_call_center_id AS cc_id,
        cc_state,
        cc_mkt_class,
        sum_return_amount,
        sum_return_qty,
        cnt_returns,
        amount_level,
        rn_state,
        running_state_sum
    FROM final_agg
) t
ORDER BY t.sum_return_amount DESC, t.cc_id
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY
