SELECT
    dr_ret.d_year AS return_year,
    s.s_state,
    CASE WHEN s.s_closed_date_sk IS NOT NULL THEN 'Closed' ELSE 'Open' END AS store_status,
    CASE WHEN dr_ret.d_month_seq % 2 = 0 THEN 'EvenMonth' ELSE 'OddMonth' END AS month_parity,
    SUM(sr.sr_net_loss) AS total_net_loss,
    SUM(i.inv_quantity_on_hand) AS total_inventory_units,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
    SUM(p.p_cost) AS total_promo_cost,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END) AS active_discount_cnt,
    AVG(sr.sr_return_quantity) AS avg_return_quantity,
    SUM(i.inv_quantity_on_hand * COALESCE(p.p_cost, 0)) AS inventory_value_times_promo_cost,
    SUM(i.inv_quantity_on_hand) / NULLIF(SUM(sr.sr_net_loss), 0) AS inv_to_loss_ratio,
    MIN(dr_ret.d_date) AS promo_start_date,
    MAX(dr_end.d_date) AS promo_end_date
FROM store_returns sr
JOIN date_dim dr_ret ON sr.sr_returned_date_sk = dr_ret.d_date_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim dr_closed ON s.s_closed_date_sk = dr_closed.d_date_sk
JOIN inventory i ON i.inv_date_sk = dr_ret.d_date_sk
JOIN promotion p ON p.p_start_date_sk = dr_ret.d_date_sk
JOIN date_dim dr_end ON p.p_end_date_sk = dr_end.d_date_sk
WHERE dr_ret.d_year BETWEEN 2000 AND 2005
  AND p.p_response_target > 100
GROUP BY
    dr_ret.d_year,
    s.s_state,
    CASE WHEN s.s_closed_date_sk IS NOT NULL THEN 'Closed' ELSE 'Open' END,
    CASE WHEN dr_ret.d_month_seq % 2 = 0 THEN 'EvenMonth' ELSE 'OddMonth' END
HAVING SUM(sr.sr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 100
