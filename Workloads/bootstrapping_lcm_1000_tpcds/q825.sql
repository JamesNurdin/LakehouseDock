WITH daily_promo_returns AS (
    SELECT
        d_start.d_year AS return_year,
        d_start.d_month_seq AS month_seq,
        d_start.d_week_seq AS week_seq,
        d_start.d_date AS promo_start_date,
        d_end.d_date AS promo_end_date,
        p.p_promo_id AS promo_id,
        p.p_promo_name AS promo_name,
        p.p_cost AS promo_cost,
        r.r_reason_desc AS reason_desc,
        s.s_store_id AS store_id,
        s.s_store_name AS store_name,
        s.s_state AS store_state,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(*) AS num_returns,
        AVG(wr.wr_fee) AS avg_fee_per_return,
        SUM(wr.wr_return_quantity) AS total_quantity
    FROM date_dim d_start
    JOIN web_returns wr ON wr.wr_returned_date_sk = d_start.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN store s ON s.s_closed_date_sk = d_start.d_date_sk
    JOIN promotion p ON p.p_start_date_sk = d_start.d_date_sk
    LEFT JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
    WHERE d_start.d_year BETWEEN 2015 AND 2017
      AND s.s_state = 'CA'
      AND r.r_reason_desc LIKE '%defect%'
    GROUP BY
        d_start.d_year,
        d_start.d_month_seq,
        d_start.d_week_seq,
        d_start.d_date,
        d_end.d_date,
        p.p_promo_id,
        p.p_promo_name,
        p.p_cost,
        r.r_reason_desc,
        s.s_store_id,
        s.s_store_name,
        s.s_state
    HAVING SUM(wr.wr_return_amt) > 1000
)
SELECT
    return_year,
    month_seq,
    week_seq,
    promo_start_date,
    promo_end_date,
    promo_id,
    promo_name,
    promo_cost,
    reason_desc,
    store_id,
    store_name,
    store_state,
    total_return_amount,
    num_returns,
    avg_fee_per_return,
    total_quantity,
    ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY total_return_amount DESC) AS rank_within_store
FROM daily_promo_returns
ORDER BY total_return_amount DESC
LIMIT 100
