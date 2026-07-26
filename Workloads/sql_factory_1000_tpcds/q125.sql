WITH ranked_losses AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        SUM(sr.sr_net_loss) AS total_net_loss,
        ROUND(100.0 * SUM(sr.sr_net_loss) / SUM(SUM(sr.sr_net_loss)) OVER (PARTITION BY d.d_year), 2) AS pct_of_yearly_loss,
        DENSE_RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(sr.sr_net_loss) DESC) AS loss_rank
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN catalog_page cp ON d.d_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
    WHERE cp.cp_type = 'Return' OR cp.cp_type IS NULL
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, d.d_year
)
SELECT *
FROM ranked_losses
WHERE loss_rank <= 3
ORDER BY d_year, loss_rank
