WITH base AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        s.s_store_id,
        s.s_store_name,
        d_ret.d_year,
        d_ret.d_month_seq,
        cr.cr_return_amount,
        cr.cr_store_credit,
        i.inv_quantity_on_hand
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN inventory i ON i.inv_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2001
      AND cc.cc_class = 'large'
      AND s.s_state = 'CA'
      AND cr.cr_return_amount > 1000
      AND i.inv_quantity_on_hand > 0
      AND d_ret.d_month_seq BETWEEN 1 AND 12
),
agg AS (
    SELECT
        cc_call_center_id,
        cc_name,
        s_store_id,
        s_store_name,
        d_year,
        d_month_seq,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_store_credit) AS total_store_credit,
        COUNT(*) AS return_cnt
    FROM base
    GROUP BY
        cc_call_center_id,
        cc_name,
        s_store_id,
        s_store_name,
        d_year,
        d_month_seq
)
SELECT
    cc_call_center_id,
    cc_name,
    s_store_id,
    s_store_name,
    d_year,
    d_month_seq,
    total_return_amount,
    total_store_credit,
    return_cnt,
    RANK() OVER (PARTITION BY d_year ORDER BY total_return_amount DESC) AS year_return_rank
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
