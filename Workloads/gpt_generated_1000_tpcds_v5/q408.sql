WITH store_loss AS (
    SELECT
        ib.ib_lower_bound AS lower_bound,
        ib.ib_upper_bound AS upper_bound,
        d.d_year AS year,
        SUM(sr.sr_net_loss) AS total_loss,
        'store' AS source
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND sr.sr_net_loss > 0
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound, d.d_year
),
catalog_loss AS (
    SELECT
        ib.ib_lower_bound AS lower_bound,
        ib.ib_upper_bound AS upper_bound,
        d.d_year AS year,
        SUM(cr.cr_net_loss) AS total_loss,
        'catalog' AS source
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND cr.cr_net_loss > 0
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound, d.d_year
)
SELECT lower_bound,
       upper_bound,
       year,
       total_loss,
       source
FROM store_loss
UNION ALL
SELECT lower_bound,
       upper_bound,
       year,
       total_loss,
       source
FROM catalog_loss
ORDER BY total_loss DESC,
         year
LIMIT 100
