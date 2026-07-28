WITH filtered_returns AS (
   SELECT
       cr.cr_net_loss,
       cr.cr_return_amount,
       cr.cr_order_number,
       cc.cc_call_center_id,
       sm.sm_ship_mode_id,
       cp.cp_catalog_page_id
   FROM catalog_returns cr
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
   WHERE cc.cc_zip = '26534'
     AND cc.cc_mkt_desc LIKE '%new%'
     AND sm.sm_type = 'OVERNIGHT'
     AND cp.cp_catalog_page_number BETWEEN 7 AND 15
     AND cr.cr_return_amount > 100
     AND ca.ca_state = 'CA'
     AND NOT EXISTS (
         SELECT 1 FROM catalog_returns cr2
         WHERE cr2.cr_order_number = cr.cr_order_number
           AND cr2.cr_ship_mode_sk <> cr.cr_ship_mode_sk
     )
),
agg_returns AS (
   SELECT
       cc_call_center_id,
       sm_ship_mode_id,
       cp_catalog_page_id,
       SUM(cr_net_loss) AS total_net_loss,
       COUNT(*) AS return_cnt,
       AVG(cr_return_amount) AS avg_return_amount
   FROM filtered_returns
   GROUP BY cc_call_center_id, sm_ship_mode_id, cp_catalog_page_id
)
SELECT
    ar.cc_call_center_id,
    AVG(ar.total_net_loss) AS avg_total_net_loss,
    SUM(ar.return_cnt) AS total_returns
FROM agg_returns ar
WHERE ar.cp_catalog_page_id NOT IN (
      SELECT cp.cp_catalog_page_id
      FROM catalog_page cp
      WHERE cp.cp_type = 'LIBRARY'
)
GROUP BY ar.cc_call_center_id
HAVING AVG(ar.total_net_loss) > 5000
ORDER BY avg_total_net_loss DESC
LIMIT 100
