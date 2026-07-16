WITH agg AS (
  SELECT
    cc.cc_company_name,
    r.r_reason_desc,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    SUM(cr.cr_store_credit) AS total_store_credit,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    AVG(hd_ref.hd_vehicle_count) AS avg_vehicle_count_refunded,
    AVG(hd_ret.hd_vehicle_count) AS avg_vehicle_count_returning,
    COUNT(*) AS total_returns
  FROM catalog_returns cr
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
  JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
  WHERE cc.cc_class = 'large'
    AND cc.cc_division IN (1, 2, 3)
    AND cp.cp_type = 'Online'
    AND cr.cr_return_amount > 0
    AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2459999
    AND hd_ref.hd_vehicle_count > 0
  GROUP BY cc.cc_company_name, r.r_reason_desc
  HAVING SUM(cr.cr_return_amount) > 10000
)
SELECT
  agg.cc_company_name,
  agg.r_reason_desc,
  agg.total_return_amount,
  agg.avg_return_quantity,
  agg.total_store_credit,
  agg.distinct_orders,
  agg.avg_vehicle_count_refunded,
  agg.avg_vehicle_count_returning,
  agg.total_returns,
  RANK() OVER (ORDER BY agg.total_return_amount DESC) AS return_amount_rank
FROM agg
ORDER BY agg.total_return_amount DESC
LIMIT 50
