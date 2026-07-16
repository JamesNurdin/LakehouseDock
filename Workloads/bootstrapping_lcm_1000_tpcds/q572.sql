WITH agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        d.d_moy AS month,
        r.r_reason_desc,
        COUNT(*) AS returns_cnt,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_quantity) AS avg_return_qty,
        COUNT(DISTINCT p_start.p_promo_name) AS distinct_start_promos,
        COUNT(DISTINCT p_end.p_promo_name) AS distinct_end_promos
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN promotion p_start ON p_start.p_start_date_sk = d.d_date_sk
    LEFT JOIN promotion p_end ON p_end.p_end_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
    GROUP BY s.s_store_id, s.s_store_name, d.d_year, d.d_moy, r.r_reason_desc
    HAVING SUM(cr.cr_net_loss) > 0
)
SELECT
    agg.s_store_id,
    agg.s_store_name,
    agg.d_year,
    agg.month,
    agg.r_reason_desc,
    agg.returns_cnt,
    agg.total_net_loss,
    agg.total_return_amount,
    agg.avg_return_qty,
    agg.distinct_start_promos,
    agg.distinct_end_promos,
    ROW_NUMBER() OVER (PARTITION BY agg.s_store_id ORDER BY agg.total_net_loss DESC) AS loss_rank
FROM agg
ORDER BY agg.total_net_loss DESC
LIMIT 100
