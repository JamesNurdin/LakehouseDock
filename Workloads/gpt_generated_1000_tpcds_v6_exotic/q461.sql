WITH refunded_agg AS (
   SELECT
       cd.cd_education_status,
       SUM(cr.cr_return_amount) AS total_return_amount,
       SUM(cr.cr_net_loss) AS total_net_loss,
       CASE WHEN SUM(cr.cr_net_loss) > 0 THEN 'Loss' ELSE 'NoLoss' END AS loss_flag
   FROM catalog_returns cr
   JOIN customer_demographics cd
       ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   WHERE cr.cr_return_tax > 20.00
       AND cd.cd_dep_count >= 1
   GROUP BY cd.cd_education_status
),
refunded AS (
   SELECT
       cd_education_status,
       total_return_amount,
       total_net_loss,
       loss_flag,
       ROW_NUMBER() OVER (PARTITION BY cd_education_status ORDER BY total_return_amount DESC) AS rn
   FROM refunded_agg
),
returning_agg AS (
   SELECT
       cd.cd_education_status,
       SUM(cr.cr_return_amount) AS total_return_amount,
       SUM(cr.cr_net_loss) AS total_net_loss,
       CASE WHEN SUM(cr.cr_net_loss) > 0 THEN 'Loss' ELSE 'NoLoss' END AS loss_flag
   FROM catalog_returns cr
   JOIN customer_demographics cd
       ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
   WHERE cr.cr_return_tax BETWEEN 10.00 AND 50.00
       AND cd.cd_education_status = 'College'
   GROUP BY cd.cd_education_status
),
returning AS (
   SELECT
       cd_education_status,
       total_return_amount,
       total_net_loss,
       loss_flag,
       ROW_NUMBER() OVER (PARTITION BY cd_education_status ORDER BY total_return_amount DESC) AS rn
   FROM returning_agg
)
SELECT
   cd_education_status,
   total_return_amount,
   total_net_loss,
   loss_flag,
   rn,
   source
FROM (
   SELECT
       cd_education_status,
       total_return_amount,
       total_net_loss,
       loss_flag,
       rn,
       'refunded' AS source
   FROM refunded
   UNION ALL
   SELECT
       cd_education_status,
       total_return_amount,
       total_net_loss,
       loss_flag,
       rn,
       'returning' AS source
   FROM returning
) combined
ORDER BY total_return_amount DESC, loss_flag
LIMIT 100
