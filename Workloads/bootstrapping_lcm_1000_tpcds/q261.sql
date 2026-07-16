SELECT
    d_return.d_year,
    d_return.d_month_seq,
    s.s_store_name,
    s.s_state,
    i.inv_item_sk,
    p.p_promo_name,
    p.p_cost,
    CASE WHEN p.p_discount_active = 'Y' THEN p.p_cost * 0.9 ELSE p.p_cost END AS adjusted_promo_cost,
    p.p_channel_tv,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_net_loss) AS total_net_loss,
    SUM(sr.sr_return_quantity) AS total_return_quantity,
    SUM(sr.sr_return_amt) / NULLIF(SUM(sr.sr_return_quantity), 0) AS avg_return_amount_per_item,
    AVG(i.inv_quantity_on_hand) AS avg_inventory_quantity,
    d_end.d_date AS promo_end_date,
    date_diff('day', d_return.d_date, d_end.d_date) AS days_until_promo_end,
    d_closed.d_date AS store_closed_date
FROM store_returns sr
JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN inventory i ON i.inv_date_sk = d_return.d_date_sk
JOIN promotion p ON p.p_start_date_sk = d_return.d_date_sk
JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
WHERE d_return.d_year >= 2000
  AND sr.sr_return_quantity > 0
  AND p.p_cost > 0
GROUP BY
    d_return.d_year,
    d_return.d_month_seq,
    s.s_store_name,
    s.s_state,
    i.inv_item_sk,
    p.p_promo_name,
    p.p_cost,
    p.p_discount_active,
    p.p_channel_tv,
    d_end.d_date,
    d_return.d_date,
    d_closed.d_date
ORDER BY total_return_amount DESC
LIMIT 100
