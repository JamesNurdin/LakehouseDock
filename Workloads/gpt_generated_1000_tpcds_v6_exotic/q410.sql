WITH store_monthly_returns AS (
    SELECT d.d_year,
           d.d_month_seq,
           SUM(sr.sr_net_loss) AS total_net_loss,
           COUNT(*) AS return_count,
           ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(sr.sr_net_loss) DESC) AS loss_rank_year
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE s.s_state = 'CA'
    GROUP BY d.d_year, d.d_month_seq
)
SELECT *
FROM (
    SELECT d_year AS year,
           d_month_seq AS month_seq,
           total_net_loss,
           return_count,
           'store' AS source,
           loss_rank_year
    FROM store_monthly_returns

    UNION ALL

    SELECT d.d_year AS year,
           d.d_month_seq AS month_seq,
           SUM(cr.cr_net_loss) AS total_net_loss,
           COUNT(*) AS return_count,
           'catalog' AS source,
           ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(cr.cr_net_loss) DESC) AS loss_rank_year
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE cr.cr_fee > 0
    GROUP BY d.d_year, d.d_month_seq
) AS combined
ORDER BY year, month_seq, source
