WITH agg AS (
    SELECT
        r.r_reason_desc,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d.d_year,
        d.d_month_seq,
        COUNT(*) AS total_returns,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_amount) AS total_return_amount,
        ROUND(AVG(cr.cr_return_quantity), 2) AS avg_return_qty,
        SUM(cr.cr_fee) AS total_fee,
        SUM(cr.cr_return_ship_cost) AS total_ship_cost,
        SUM(cr.cr_store_credit) AS total_store_credit,
        SUM(cr.cr_reversed_charge) AS total_reversed_charge
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2005
      AND s.s_state = 'CA'
    GROUP BY
        r.r_reason_desc,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d.d_year,
        d.d_month_seq
)
SELECT
    agg.r_reason_desc,
    agg.s_store_name,
    agg.s_city,
    agg.s_state,
    agg.d_year,
    agg.d_month_seq,
    agg.total_returns,
    agg.total_net_loss,
    agg.total_return_amount,
    agg.avg_return_qty,
    agg.total_fee,
    agg.total_ship_cost,
    agg.total_store_credit,
    agg.total_reversed_charge,
    (agg.total_net_loss / NULLIF(agg.total_returns, 0)) AS net_loss_per_return,
    CASE
        WHEN agg.total_net_loss > 1000 THEN 'High'
        WHEN agg.total_net_loss > 500 THEN 'Medium'
        ELSE 'Low'
    END AS loss_category,
    ROW_NUMBER() OVER (PARTITION BY agg.s_store_name ORDER BY agg.total_net_loss DESC) AS store_reason_rank
FROM agg
WHERE agg.total_net_loss > 0
ORDER BY agg.total_net_loss DESC
LIMIT 100
