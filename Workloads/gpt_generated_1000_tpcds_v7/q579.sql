WITH cr_base AS (
  SELECT
    cr.cr_return_amount,
    cr.cr_net_loss,
    cr.cr_returned_date_sk,
    cr.cr_item_sk,
    cr.cr_refunded_customer_sk,
    cr.cr_returning_customer_sk,
    cr.cr_call_center_sk,
    cr.cr_catalog_page_sk,
    cr.cr_ship_mode_sk,
    cr.cr_reason_sk
  FROM catalog_returns cr
),
wr_base AS (
  SELECT
    wr.wr_return_amt,
    wr.wr_net_loss,
    wr.wr_returned_date_sk,
    wr.wr_item_sk,
    wr.wr_refunded_customer_sk,
    wr.wr_returning_customer_sk,
    wr.wr_reason_sk
  FROM web_returns wr
)
SELECT
  d_ret.d_year AS return_year,
  COUNT(DISTINCT c_refunded.c_customer_sk) AS refunded_customers,
  SUM(cr_base.cr_return_amount) AS total_catalog_return_amount,
  SUM(wr_base.wr_return_amt) AS total_web_return_amount,
  (SUM(cr_base.cr_net_loss) + SUM(wr_base.wr_net_loss)) AS total_net_loss,
  COUNT(DISTINCT p.p_promo_id) AS promotion_count,
  COUNT(DISTINCT cc.cc_call_center_sk) AS distinct_call_centers,
  COUNT(DISTINCT sm.sm_ship_mode_sk) AS distinct_ship_modes
FROM cr_base
JOIN item i ON cr_base.cr_item_sk = i.i_item_sk
JOIN customer c_refunded ON cr_base.cr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN customer c_returning ON cr_base.cr_returning_customer_sk = c_returning.c_customer_sk
JOIN call_center cc ON cr_base.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cr_base.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cr_base.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN reason r ON cr_base.cr_reason_sk = r.r_reason_sk
JOIN date_dim d_ret ON cr_base.cr_returned_date_sk = d_ret.d_date_sk
JOIN wr_base ON wr_base.wr_item_sk = i.i_item_sk
JOIN date_dim d_web ON wr_base.wr_returned_date_sk = d_web.d_date_sk
JOIN reason r2 ON wr_base.wr_reason_sk = r2.r_reason_sk
JOIN promotion p ON p.p_item_sk = i.i_item_sk
JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE d_ret.d_year BETWEEN 2000 AND 2002
GROUP BY d_ret.d_year
ORDER BY d_ret.d_year
