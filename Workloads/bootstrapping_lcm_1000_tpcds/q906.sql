SELECT
    d_return.d_year,
    d_return.d_month_seq,
    CASE WHEN s.s_state IN ('CA', 'OR', 'WA') THEN 'West Coast' ELSE 'Other' END AS region,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_tickets,
    SUM(sr.sr_net_loss) AS store_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
    SUM(cr.cr_net_loss) AS catalog_net_loss,
    COUNT(DISTINCT p.p_promo_id) AS promo_count,
    SUM(p.p_cost) AS total_promo_cost
FROM catalog_returns cr
JOIN date_dim d_return ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN promotion p ON TRUE
JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
WHERE d_start.d_date_sk <= d_return.d_date_sk
  AND d_end.d_date_sk >= d_return.d_date_sk
GROUP BY
    d_return.d_year,
    d_return.d_month_seq,
    CASE WHEN s.s_state IN ('CA', 'OR', 'WA') THEN 'West Coast' ELSE 'Other' END
HAVING COUNT(*) > 10
ORDER BY d_return.d_year, d_return.d_month_seq
LIMIT 100
