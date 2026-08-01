WITH avg_loss AS (
    SELECT AVG(cr_net_loss) AS avg_net_loss
    FROM catalog_returns
),
married_refunds AS (
    SELECT cc.cc_name AS call_center_name,
           SUM(cr.cr_net_loss) AS total_net_loss,
           AVG(cr.cr_return_quantity) AS avg_return_qty
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    WHERE cd_ref.cd_marital_status = 'M'
      AND EXISTS (
          SELECT 1
          FROM customer_demographics cd_ret
          WHERE cd_ret.cd_demo_sk = cr.cr_returning_cdemo_sk
            AND cd_ret.cd_dep_count > 2
      )
    GROUP BY cc.cc_name
    HAVING SUM(cr.cr_net_loss) > (SELECT avg_net_loss FROM avg_loss)
),
single_refunds AS (
    SELECT cc.cc_name AS call_center_name,
           SUM(cr.cr_net_loss) AS total_net_loss,
           AVG(cr.cr_return_quantity) AS avg_return_qty
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    WHERE cd_ref.cd_marital_status = 'S'
      AND cc.cc_class = 'large'
    GROUP BY cc.cc_name
    HAVING SUM(cr.cr_net_loss) > (SELECT avg_net_loss FROM avg_loss)
)
SELECT DISTINCT
    call_center_name,
    total_net_loss,
    avg_return_qty
FROM (
    SELECT call_center_name, total_net_loss, avg_return_qty FROM married_refunds
    UNION ALL
    SELECT call_center_name, total_net_loss, avg_return_qty FROM single_refunds
) combined
ORDER BY total_net_loss DESC
LIMIT 100
