WITH base AS (
  SELECT
    cc.cc_call_center_id,
    cc.cc_state,
    cc.cc_employees,
    p.p_promo_name,
    sm.sm_type,
    SUM(cs.cs_quantity) AS total_quantity_sold,
    SUM(cs.cs_net_profit) AS total_sales_profit,
    SUM(cs.cs_ext_discount_amt) AS total_discount_amount,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amount,
    COALESCE(SUM(dr.return_quantity), 0) AS total_return_quantity,
    COALESCE(SUM(dr.return_loss), 0) AS total_return_loss
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN (
      SELECT
          wr.wr_refunded_hdemo_sk,
          wr.wr_return_quantity AS return_quantity,
          wr.wr_net_loss AS return_loss
      FROM web_returns wr
      JOIN reason rsn ON wr.wr_reason_sk = rsn.r_reason_sk
      WHERE rsn.r_reason_desc = 'Damaged'
  ) dr ON dr.wr_refunded_hdemo_sk = hd.hd_demo_sk
  WHERE
    cs.cs_sold_date_sk BETWEEN 2450806 AND 2451063
    AND cc.cc_state = 'TN'
    AND cc.cc_employees > 1000000
    AND p.p_channel_email = 'Y'
    AND p.p_discount_active = 'Y'
    AND sm.sm_type = 'AIR'
    AND cp.cp_type = 'Catalog'
  GROUP BY
    cc.cc_call_center_id,
    cc.cc_state,
    cc.cc_employees,
    p.p_promo_name,
    sm.sm_type
)
SELECT
  cc_call_center_id,
  cc_state,
  cc_employees,
  p_promo_name,
  sm_type,
  total_quantity_sold,
  total_sales_profit,
  total_discount_amount,
  avg_discount_amount,
  total_return_quantity,
  total_return_loss,
  (total_sales_profit - total_return_loss) AS net_profit_adjusted,
  (total_sales_profit - total_return_loss) / NULLIF(cc_employees, 0) AS profit_per_employee,
  RANK() OVER (ORDER BY (total_sales_profit - total_return_loss) / NULLIF(cc_employees, 0) DESC) AS profit_rank
FROM base
ORDER BY profit_per_employee DESC
LIMIT 100
