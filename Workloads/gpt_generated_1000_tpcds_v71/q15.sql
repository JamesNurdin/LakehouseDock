WITH cr AS (
    SELECT 
        d.d_year AS year,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cr.cr_net_loss) AS total_loss,
        CASE WHEN SUM(cr.cr_net_loss) > 10000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE EXISTS (
        SELECT 1
        FROM ship_mode sm
        WHERE cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
          AND sm.sm_type = 'AIR'
    )
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, ib.ib_lower_bound, ib.ib_upper_bound
),
wr AS (
    SELECT 
        d.d_year AS year,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(wr.wr_net_loss) AS total_loss,
        CASE WHEN SUM(wr.wr_net_loss) > 10000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE EXISTS (
        SELECT 1
        FROM web_page wp
        WHERE wr.wr_web_page_sk = wp.wp_web_page_sk
          AND wp.wp_type = 'article'
    )
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT DISTINCT year,
                ib_lower_bound,
                ib_upper_bound,
                total_loss,
                loss_category
FROM cr
UNION ALL
SELECT DISTINCT year,
                ib_lower_bound,
                ib_upper_bound,
                total_loss,
                loss_category
FROM wr
ORDER BY year, total_loss DESC
LIMIT 100
