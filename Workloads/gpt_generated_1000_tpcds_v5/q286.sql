WITH returning AS (
    SELECT ib.ib_lower_bound AS lower_bound,
           ib.ib_upper_bound AS upper_bound,
           SUM(cr.cr_net_loss) AS total_net_loss,
           CASE WHEN SUM(cr.cr_net_loss) > 0 THEN 'Positive' ELSE 'Non-Positive' END AS loss_category,
           'Returning' AS customer_role
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cr.cr_return_amount > 100
      AND cd.cd_marital_status = 'S'
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
),
refunded AS (
    SELECT ib.ib_lower_bound AS lower_bound,
           ib.ib_upper_bound AS upper_bound,
           SUM(cr.cr_net_loss) AS total_net_loss,
           CASE WHEN SUM(cr.cr_net_loss) > 0 THEN 'Positive' ELSE 'Non-Positive' END AS loss_category,
           'Refunded' AS customer_role
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cr.cr_reversed_charge > 50
      AND cd.cd_marital_status = 'M'
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT lower_bound,
       upper_bound,
       total_net_loss,
       loss_category,
       customer_role
FROM returning
UNION ALL
SELECT lower_bound,
       upper_bound,
       total_net_loss,
       loss_category,
       customer_role
FROM refunded
ORDER BY total_net_loss DESC
LIMIT 100
