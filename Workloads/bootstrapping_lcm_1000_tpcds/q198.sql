WITH agg AS (
    SELECT
        d.d_year,
        r.r_reason_desc,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(i.inv_quantity_on_hand) AS avg_inventory_on_hand,
        COUNT(DISTINCT s.s_store_sk) AS closed_store_count,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        AVG(cr.cr_return_amount) AS avg_return_amount
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2015 AND 2020
      AND s.s_state = 'CA'
    GROUP BY d.d_year, r.r_reason_desc
)
SELECT
    d_year,
    r_reason_desc,
    total_net_loss,
    avg_inventory_on_hand,
    closed_store_count,
    total_return_qty,
    avg_return_amount,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS net_loss_rank
FROM agg
ORDER BY d_year, net_loss_rank
LIMIT 100
