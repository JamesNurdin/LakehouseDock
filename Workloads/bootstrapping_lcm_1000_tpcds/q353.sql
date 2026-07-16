WITH agg AS (
    SELECT
        dd.d_year,
        dd.d_month_seq,
        st.s_store_id,
        st.s_state,
        r.r_reason_desc,
        COUNT(*) AS return_count,
        SUM(cr.cr_return_quantity) AS total_quantity,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
        COUNT(DISTINCT p_start.p_promo_id) AS promotions_started,
        COUNT(DISTINCT p_end.p_promo_id) AS promotions_ended,
        MAX(p_start.p_promo_name) AS promotion_started_name,
        MAX(p_end.p_promo_name) AS promotion_ended_name
    FROM catalog_returns cr
    JOIN date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store st ON st.s_closed_date_sk = dd.d_date_sk
    LEFT JOIN promotion p_start ON p_start.p_start_date_sk = dd.d_date_sk
    LEFT JOIN promotion p_end ON p_end.p_end_date_sk = dd.d_date_sk
    GROUP BY dd.d_year, dd.d_month_seq, st.s_store_id, st.s_state, r.r_reason_desc
)
SELECT
    agg.*,
    ROW_NUMBER() OVER (PARTITION BY agg.s_store_id ORDER BY agg.total_net_loss DESC) AS store_net_loss_rank
FROM agg
ORDER BY agg.total_net_loss DESC, agg.return_count DESC
LIMIT 200
