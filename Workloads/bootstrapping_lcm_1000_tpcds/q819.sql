SELECT
    d_base.d_year,
    d_base.d_current_month,
    s.s_store_name,
    s.s_state,
    ws.web_name,
    ws.web_city,
    ws.web_state,
    p.p_promo_name,
    p.p_channel_tv,
    d_promo_end.d_current_quarter AS promo_end_quarter,
    d_site_close.d_current_quarter AS site_close_quarter,
    SUM(wr.wr_return_amt) AS total_return_amt,
    SUM(wr.wr_return_tax) AS total_return_tax,
    SUM(wr.wr_net_loss) AS total_net_loss,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    AVG(p.p_cost) AS avg_promo_cost,
    SUM(wr.wr_return_amt) / NULLIF(AVG(p.p_cost), 0) AS return_to_cost_ratio,
    SUM(wr.wr_return_quantity) AS total_return_qty
FROM date_dim d_base
JOIN web_returns wr ON wr.wr_returned_date_sk = d_base.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_base.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d_base.d_date_sk
JOIN promotion p ON p.p_start_date_sk = d_base.d_date_sk
JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN date_dim d_site_close ON ws.web_close_date_sk = d_site_close.d_date_sk
WHERE s.s_state = 'CA'
  AND ws.web_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND d_base.d_year = 2022
GROUP BY
    d_base.d_year,
    d_base.d_current_month,
    s.s_store_name,
    s.s_state,
    ws.web_name,
    ws.web_city,
    ws.web_state,
    p.p_promo_name,
    p.p_channel_tv,
    d_promo_end.d_current_quarter,
    d_site_close.d_current_quarter
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_return_amt DESC
LIMIT 100
