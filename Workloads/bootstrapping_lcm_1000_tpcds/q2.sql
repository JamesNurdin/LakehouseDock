SELECT
    d.d_year,
    d.d_month_seq,
    s.s_store_id,
    s.s_city,
    s.s_state,
    hd_refunded.hd_income_band_sk AS refunded_income_band,
    hd_refunded.hd_vehicle_count AS refunded_vehicle_count,
    hd_returning.hd_income_band_sk AS returning_income_band,
    hd_returning.hd_vehicle_count AS returning_vehicle_count,
    p_start.p_promo_id AS start_promo_id,
    p_start.p_promo_name AS start_promo_name,
    p_end.p_promo_id AS end_promo_id,
    p_end.p_promo_name AS end_promo_name,
    COUNT(DISTINCT cr.cr_order_number) AS num_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_qty
FROM catalog_returns cr
INNER JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
INNER JOIN household_demographics hd_refunded
    ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
INNER JOIN household_demographics hd_returning
    ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
INNER JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
INNER JOIN promotion p_start
    ON p_start.p_start_date_sk = d.d_date_sk
INNER JOIN promotion p_end
    ON p_end.p_end_date_sk = d.d_date_sk
WHERE p_start.p_discount_active = 'Y'
  AND s.s_state = 'CA'
  AND d.d_year BETWEEN 2000 AND 2005
GROUP BY
    d.d_year,
    d.d_month_seq,
    s.s_store_id,
    s.s_city,
    s.s_state,
    hd_refunded.hd_income_band_sk,
    hd_refunded.hd_vehicle_count,
    hd_returning.hd_income_band_sk,
    hd_returning.hd_vehicle_count,
    p_start.p_promo_id,
    p_start.p_promo_name,
    p_end.p_promo_id,
    p_end.p_promo_name
ORDER BY total_net_loss DESC
LIMIT 100
