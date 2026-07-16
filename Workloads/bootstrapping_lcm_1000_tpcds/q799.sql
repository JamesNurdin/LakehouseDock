SELECT
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state,
    p.p_promo_name,
    p.p_cost,
    p.p_response_target,
    d_return.d_year,
    d_return.d_month_seq,
    d_return.d_date AS return_date,
    CASE WHEN d_return.d_weekend = 'Y' THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    ca_refunded.ca_city AS refunded_city,
    ca_returning.ca_city AS returning_city,
    COUNT(DISTINCT cr.cr_order_number) AS returns_count,
    SUM(cr.cr_return_quantity) AS total_return_qty,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_fee) AS total_fee,
    (SUM(cr.cr_net_loss) / NULLIF(SUM(cr.cr_return_amount), 0)) AS loss_to_amount_ratio,
    d_promo_end.d_date AS promo_end_date,
    DATE_DIFF('day', d_return.d_date, d_promo_end.d_date) AS promo_duration_days
FROM catalog_returns cr
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN customer_address ca_refunded
    ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer_address ca_returning
    ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_return.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE d_return.d_year = 2001
  AND s.s_state = 'CA'
  AND p.p_discount_active = 'Y'
GROUP BY
    s.s_store_name,
    s.s_city,
    s.s_state,
    p.p_promo_name,
    p.p_cost,
    p.p_response_target,
    d_return.d_year,
    d_return.d_month_seq,
    d_return.d_date,
    d_return.d_weekend,
    ca_refunded.ca_city,
    ca_returning.ca_city,
    d_promo_end.d_date
HAVING SUM(cr.cr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 100
