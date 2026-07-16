WITH agg AS (
    SELECT
        s.s_store_id,
        s.s_state,
        d.d_year,
        d.d_month_seq,
        r.r_reason_desc,
        COUNT(cr.cr_order_number) AS total_returns,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_tax) AS avg_return_tax,
        SUM(cr.cr_return_amount) AS total_return_amount,
        MAX(p_start.p_discount_active) AS start_discount_active,
        MAX(p_end.p_discount_active) AS end_discount_active
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN promotion p_start
        ON p_start.p_start_date_sk = d.d_date_sk
    JOIN promotion p_end
        ON p_end.p_end_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2020
      AND s.s_state IS NOT NULL
    GROUP BY s.s_store_id, s.s_state, d.d_year, d.d_month_seq, r.r_reason_desc
    HAVING SUM(cr.cr_net_loss) > 0
)
SELECT
    s_store_id,
    s_state,
    d_year,
    d_month_seq,
    r_reason_desc,
    total_returns,
    total_net_loss,
    avg_return_tax,
    total_return_amount,
    start_discount_active,
    end_discount_active,
    ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY total_net_loss DESC) AS state_rank_by_loss,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS year_rank_by_loss
FROM agg
ORDER BY total_net_loss DESC
LIMIT 200
