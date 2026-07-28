WITH overall_avg AS (
   SELECT AVG(cr_net_loss) AS avg_net_loss
   FROM catalog_returns
),
aggregated AS (
   SELECT
       cp.cp_department,
       cp.cp_catalog_page_number,
       sm.sm_code,
       cd.cd_gender,
       SUM(cr.cr_net_loss) AS total_net_loss
   FROM catalog_returns cr
   JOIN catalog_page cp
     ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm
     ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN customer_demographics cd
     ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   JOIN web_returns wr
     ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
   WHERE cp.cp_type = 'quarterly'
     AND cp.cp_catalog_page_number BETWEEN 10 AND 20
     AND sm.sm_code IN ('AIR', 'SEA')
     AND cd.cd_gender = 'F'
     AND cr.cr_return_quantity > 1
   GROUP BY
       cp.cp_department,
       cp.cp_catalog_page_number,
       sm.sm_code,
       cd.cd_gender
)
SELECT
    a.cp_department,
    a.cp_catalog_page_number,
    a.sm_code,
    a.cd_gender,
    a.total_net_loss,
    CASE WHEN a.sm_code = 'AIR' THEN 'Air' ELSE 'Other' END AS ship_mode_group,
    AVG(a.total_net_loss) OVER (PARTITION BY a.cp_department) AS avg_net_loss_by_dept,
    CASE WHEN a.total_net_loss > (SELECT avg_net_loss FROM overall_avg) THEN 'Above Avg' ELSE 'Below Avg' END AS loss_vs_overall,
    RANK() OVER (ORDER BY a.total_net_loss DESC) AS loss_rank
FROM aggregated a
ORDER BY a.total_net_loss DESC
LIMIT 100
