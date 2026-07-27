SELECT *
FROM (
    SELECT
        cc.cc_call_center_id AS region_key,
        SUM(cr.cr_net_loss) AS total_loss,
        CASE
            WHEN cd.cd_credit_rating = 'High Risk' THEN 'HIGH'
            WHEN cd.cd_credit_rating = 'Low Risk' THEN 'LOW'
            ELSE 'MEDIUM'
        END AS rating_category
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cp.cp_type = 'Online'
      AND EXISTS (
          SELECT 1 FROM catalog_page cp2
          WHERE cp2.cp_catalog_page_sk = cr.cr_catalog_page_sk
            AND cp2.cp_department = 'Electronics'
      )
    GROUP BY cc.cc_call_center_id, cd.cd_credit_rating
    UNION ALL
    SELECT
        CAST(sr.sr_store_sk AS VARCHAR) AS region_key,
        SUM(sr.sr_net_loss) AS total_loss,
        CASE
            WHEN cd.cd_credit_rating = 'High Risk' THEN 'HIGH'
            WHEN cd.cd_credit_rating = 'Low Risk' THEN 'LOW'
            ELSE 'MEDIUM'
        END AS rating_category
    FROM store_returns sr
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE sr.sr_return_quantity > 1
      AND cd.cd_dep_employed_count >= 2
    GROUP BY sr.sr_store_sk, cd.cd_credit_rating
) AS combined
ORDER BY total_loss DESC, region_key
LIMIT 100
