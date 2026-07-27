WITH catalog_branch AS (
  SELECT
    'catalog' AS source_type,
    cs.cs_item_sk AS item_sk,
    cs.cs_sold_date_sk AS date_sk,
    td_sales.t_hour AS hour_of_day,
    CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
    cs.cs_net_paid,
    cr.cr_return_amount,
    p.p_promo_name AS promotion_name,
    cc.cc_name AS call_center_name,
    cp.cp_department AS department,
    NULL AS store_name,
    NULL AS web_url,
    ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_sold_date_sk DESC) AS sales_rank
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN time_dim td_sales ON cs.cs_sold_time_sk = td_sales.t_time_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_item_sk = cs.cs_item_sk
   AND cr.cr_order_number = cs.cs_order_number
  LEFT JOIN time_dim td_ret ON cr.cr_returned_time_sk = td_ret.t_time_sk
  LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
  LEFT JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
  LEFT JOIN call_center cc_cr ON cr.cr_call_center_sk = cc_cr.cc_call_center_sk
  LEFT JOIN catalog_page cp_cr ON cr.cr_catalog_page_sk = cp_cr.cp_catalog_page_sk
),
store_branch AS (
  SELECT
    'store' AS source_type,
    sr.sr_item_sk AS item_sk,
    sr.sr_returned_date_sk AS date_sk,
    td.t_hour AS hour_of_day,
    NULL AS profit_flag,
    NULL AS cs_net_paid,
    sr.sr_return_amt AS cr_return_amount,
    NULL AS promotion_name,
    NULL AS call_center_name,
    NULL AS department,
    s.s_store_name AS store_name,
    NULL AS web_url,
    ROW_NUMBER() OVER (PARTITION BY sr.sr_item_sk ORDER BY sr.sr_returned_date_sk DESC) AS sales_rank
  FROM store_returns sr
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
  LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
),
web_branch AS (
  SELECT
    'web' AS source_type,
    wr.wr_item_sk AS item_sk,
    wr.wr_returned_date_sk AS date_sk,
    td.t_hour AS hour_of_day,
    NULL AS profit_flag,
    NULL AS cs_net_paid,
    wr.wr_return_amt AS cr_return_amount,
    NULL AS promotion_name,
    NULL AS call_center_name,
    NULL AS department,
    NULL AS store_name,
    wp.wp_url AS web_url,
    ROW_NUMBER() OVER (PARTITION BY wr.wr_item_sk ORDER BY wr.wr_returned_date_sk DESC) AS sales_rank
  FROM web_returns wr
  LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
  LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
)
SELECT
  ub.source_type,
  ub.item_sk,
  ub.date_sk,
  ub.hour_of_day,
  ub.profit_flag,
  SUM(ub.cs_net_paid) AS total_net_paid,
  SUM(ub.cr_return_amount) AS total_return_amount,
  COUNT(*) AS transaction_cnt,
  AVG(
    (SELECT AVG(cr2.cr_return_amount)
     FROM catalog_returns cr2
     WHERE cr2.cr_item_sk = ub.item_sk)
  ) AS avg_item_return_amount,
  MAX(ub.promotion_name) AS any_promotion_name,
  MAX(ub.store_name) AS any_store_name,
  MAX(ub.web_url) AS any_web_url,
  CASE WHEN SUM(ub.cs_net_paid) > 0 THEN 'Positive' ELSE 'Non‑Positive' END AS net_paid_category
FROM (
  SELECT * FROM catalog_branch
  UNION ALL
  SELECT * FROM store_branch
  UNION ALL
  SELECT * FROM web_branch
) ub
GROUP BY
  ub.source_type,
  ub.item_sk,
  ub.date_sk,
  ub.hour_of_day,
  ub.profit_flag
ORDER BY
  total_net_paid DESC,
  ub.profit_flag DESC
LIMIT 100
