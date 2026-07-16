SELECT
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS month_seq,
    sm.sm_type AS ship_mode,
    cd_ref.cd_gender AS refunded_gender,
    cd_ref.cd_marital_status AS refunded_marital_status,
    cd_ret.cd_gender AS returning_gender,
    cd_ret.cd_marital_status AS returning_marital_status,
    s.s_state,
    s.s_city,
    d_store.d_year AS store_closed_year,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    SUM(cr.cr_fee) AS total_fee,
    SUM(CASE WHEN cr.cr_return_tax > 0 THEN 1 ELSE 0 END) AS returns_with_tax,
    SUM(CASE WHEN cr.cr_return_amount > cr.cr_fee THEN 1 ELSE 0 END) AS returns_amount_gt_fee,
    SUM(cr.cr_return_amount) / NULLIF(COUNT(*), 0) AS avg_return_amount
FROM catalog_returns cr
JOIN date_dim d_ret
  ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd_ref
  ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_demographics cd_ret
  ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN store s
  ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN date_dim d_store
  ON s.s_closed_date_sk = d_store.d_date_sk
WHERE d_ret.d_year BETWEEN 2000 AND 2005
GROUP BY
    d_ret.d_year,
    d_ret.d_month_seq,
    sm.sm_type,
    cd_ref.cd_gender,
    cd_ref.cd_marital_status,
    cd_ret.cd_gender,
    cd_ret.cd_marital_status,
    s.s_state,
    s.s_city,
    d_store.d_year
HAVING COUNT(*) > 5
ORDER BY total_return_amount DESC
LIMIT 200
