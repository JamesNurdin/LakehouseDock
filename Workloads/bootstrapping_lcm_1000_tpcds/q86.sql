WITH agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        d.d_year,
        d.d_quarter_seq,
        r.r_reason_desc,
        sm.sm_type,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        AVG(cr.cr_return_amt_inc_tax) AS avg_return_amt_inc_tax
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2015 AND 2020
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        d.d_year,
        d.d_quarter_seq,
        r.r_reason_desc,
        sm.sm_type
    HAVING SUM(cr.cr_net_loss) > 0
)
SELECT
    agg.s_store_id,
    agg.s_store_name,
    agg.s_city,
    agg.d_year,
    agg.d_quarter_seq,
    agg.r_reason_desc,
    agg.sm_type,
    agg.total_net_loss,
    agg.total_return_qty,
    agg.avg_return_amt_inc_tax,
    ROW_NUMBER() OVER (PARTITION BY agg.s_store_id, agg.d_year, agg.d_quarter_seq ORDER BY agg.total_net_loss DESC) AS loss_rank
FROM agg
ORDER BY agg.total_net_loss DESC
LIMIT 100
