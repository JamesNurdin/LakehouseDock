SELECT
    d_ret.d_year,
    s.s_state,
    ws_open.web_state AS web_state_open,
    ws_close.web_state AS web_state_close,
    CASE WHEN d_ret.d_month_seq % 2 = 0 THEN 'EvenMonth' ELSE 'OddMonth' END AS month_parity,
    COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
    SUM(sr.sr_net_loss) AS total_net_loss,
    SUM(sr.sr_return_amt) AS total_return_amt,
    COUNT(DISTINCT p.p_promo_id) AS distinct_promos,
    SUM(p.p_cost) AS total_promo_cost,
    MAX(d_close.d_date) AS store_close_date,
    SUM(sr.sr_net_loss) FILTER (WHERE p.p_discount_active = 'Y') AS net_loss_with_active_discount
FROM store_returns sr
JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN date_dim d_close ON s.s_closed_date_sk = d_close.d_date_sk
JOIN web_site ws_open ON ws_open.web_open_date_sk = d_ret.d_date_sk
JOIN web_site ws_close ON ws_close.web_close_date_sk = d_ret.d_date_sk
JOIN promotion p ON p.p_start_date_sk = d_ret.d_date_sk
GROUP BY
    d_ret.d_year,
    s.s_state,
    ws_open.web_state,
    ws_close.web_state,
    CASE WHEN d_ret.d_month_seq % 2 = 0 THEN 'EvenMonth' ELSE 'OddMonth' END
HAVING COUNT(DISTINCT sr.sr_ticket_number) > 5
ORDER BY total_net_loss DESC
LIMIT 100
