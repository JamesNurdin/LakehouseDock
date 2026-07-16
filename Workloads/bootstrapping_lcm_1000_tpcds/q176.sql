SELECT
    s.s_store_id,
    s.s_city,
    s.s_state,
    d_return.d_year,
    d_return.d_month_seq,
    cp.cp_type,
    cp.cp_catalog_page_number,
    p.p_promo_name,
    p.p_purpose,
    SUM(sr.sr_net_loss) AS total_net_loss,
    SUM(sr.sr_return_quantity) AS total_return_qty,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets
FROM store_returns sr
JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_return.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_return.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE d_return.d_year = 2023
  AND p.p_discount_active = 'Y'
GROUP BY s.s_store_id, s.s_city, s.s_state,
         d_return.d_year, d_return.d_month_seq,
         cp.cp_type, cp.cp_catalog_page_number,
         p.p_promo_name, p.p_purpose
ORDER BY total_net_loss DESC
LIMIT 100
