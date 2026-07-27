WITH agg AS (
    SELECT
        d_ret.d_year,
        sm.sm_type,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS cnt_returns
    FROM catalog_returns cr
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN web_page wp
        ON wp.wp_type = 'article'
    JOIN date_dim d_create
        ON wp.wp_creation_date_sk = d_create.d_date_sk
    JOIN date_dim d_access
        ON wp.wp_access_date_sk = d_access.d_date_sk
    WHERE cr.cr_return_tax > 10
      AND cr.cr_return_amount > 50
      AND sm.sm_code IN ('AIR', 'SEA')
      AND d_ret.d_year BETWEEN 1999 AND 2001
      AND sr.sr_return_quantity > 1
      AND d_ret.d_current_year = 'N'
    GROUP BY GROUPING SETS ((d_ret.d_year, sm.sm_type), (d_ret.d_year), ())
    HAVING SUM(cr.cr_net_loss) > 1000
)
SELECT
    d_year,
    sm_type,
    total_return_amount,
    total_net_loss,
    cnt_returns,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS net_loss_rank,
    CASE
        WHEN total_net_loss > (SELECT AVG(cr_net_loss) FROM catalog_returns) THEN 'ABOVE_AVG'
        ELSE 'BELOW_AVG'
    END AS net_loss_vs_avg
FROM agg
ORDER BY d_year, net_loss_rank
LIMIT 100
