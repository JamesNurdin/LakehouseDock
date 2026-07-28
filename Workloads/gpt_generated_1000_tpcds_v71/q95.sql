WITH filtered AS (
   SELECT cr.cr_call_center_sk,
          cr.cr_warehouse_sk,
          cr.cr_reason_sk,
          cr.cr_return_quantity,
          cr.cr_return_amount,
          cr.cr_net_loss,
          cc.cc_call_center_id,
          cc.cc_market_manager,
          cc.cc_state,
          w.w_city,
          w.w_county,
          r.r_reason_desc AS r_reason_desc
   FROM tpcds.catalog_returns cr
   JOIN tpcds.call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN tpcds.warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN tpcds.reason r ON cr.cr_reason_sk = r.r_reason_sk
   WHERE cr.cr_return_quantity > 1
     AND cr.cr_return_amount > 100
     AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2451000
     AND r.r_reason_id = 'AAAAAAAAPAAAAAAA'
     AND cc.cc_market_manager = 'James Mcdonald'
     AND w.w_county = 'Ziebach County'
)
SELECT
   cc_call_center_id,
   cc_market_manager,
   w_city,
   w_county,
   r_reason_desc,
   COUNT(*) AS return_cnt,
   SUM(cr_return_amount) AS total_return_amount,
   AVG(cr_net_loss) AS avg_net_loss,
   MIN(cr_return_amount) AS min_return_amount,
   MAX(cr_return_amount) AS max_return_amount
FROM filtered
GROUP BY
   cc_call_center_id,
   cc_market_manager,
   w_city,
   w_county,
   r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100
