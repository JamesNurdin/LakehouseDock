WITH base AS (
  SELECT
    cr.cr_returned_date_sk,
    cr.cr_returned_time_sk,
    cr.cr_warehouse_sk,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    cr.cr_net_loss,
    cr.cr_order_number,
    cr.cr_fee,
    cr.cr_return_ship_cost,
    cr.cr_refunded_cash,
    wr.wr_returned_date_sk,
    wr.wr_returned_time_sk,
    wr.wr_return_amt,
    wr.wr_return_tax,
    wr.wr_net_loss,
    wr.wr_order_number,
    wr.wr_return_quantity,
    wr.wr_fee,
    wr.wr_return_ship_cost,
    wr.wr_refunded_cash,
    d.d_date,
    d.d_year,
    d.d_month_seq,
    d.d_day_name,
    t.t_sub_shift,
    t.t_hour,
    w.w_warehouse_name,
    w.w_state,
    p.p_promo_name,
    p.p_channel_demo,
    p.p_discount_active,
    wp.wp_max_ad_count,
    wp.wp_url
  FROM catalog_returns cr
  JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
  JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
   AND wr.wr_returned_time_sk = t.t_time_sk
  JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
  JOIN promotion p
    ON p.p_start_date_sk = d.d_date_sk
)
SELECT
  d_year,
  d_month_seq,
  w_state,
  p_channel_demo,
  CASE WHEN p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
  COUNT(DISTINCT cr_order_number) AS catalog_orders,
  COUNT(DISTINCT wr_order_number) AS web_orders,
  SUM(cr_return_amount) AS total_catalog_return_amount,
  SUM(wr_return_amt) AS total_web_return_amount,
  AVG(cr_return_quantity) AS avg_catalog_return_qty,
  MAX(wr_return_tax) AS max_web_return_tax,
  SUM(CASE WHEN t_sub_shift = 'morning' THEN cr_return_amount ELSE 0 END) AS morning_catalog_return_amount,
  SUM(CASE WHEN wp_max_ad_count > 2 THEN wr_return_amt ELSE 0 END) AS high_ad_web_return_amount
FROM base
WHERE
  d_year = 2001
  AND d_month_seq BETWEEN 1200 AND 1220
  AND t_sub_shift IN ('morning', 'afternoon')
  AND w_state = 'CA'
  AND p_channel_demo = 'N'
  AND wp_max_ad_count >= 2
GROUP BY
  d_year,
  d_month_seq,
  w_state,
  p_channel_demo,
  CASE WHEN p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END
ORDER BY total_catalog_return_amount DESC
LIMIT 100
