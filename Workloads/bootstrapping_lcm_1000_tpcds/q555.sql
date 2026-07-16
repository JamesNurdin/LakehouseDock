SELECT
    d_return.d_current_year,
    d_return.d_quarter_name,
    d_closed.d_current_quarter,
    s.s_state,
    s.s_city,
    COUNT(DISTINCT sr.sr_ticket_number) AS total_tickets,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_return_quantity) AS avg_return_qty,
    SUM(CASE WHEN t.t_meal_time = 'Lunch' THEN sr.sr_return_amt ELSE 0 END) AS lunch_return_amt,
    COUNT(CASE WHEN wp.wp_type = 'Landing' THEN 1 END) AS landing_page_count,
    SUM(CASE WHEN wp.wp_image_count > 5 THEN wp.wp_image_count * sr.sr_return_quantity ELSE 0 END) AS image_weighted_return_qty
FROM store_returns sr
JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN time_dim t
    ON sr.sr_return_time_sk = t.t_time_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_return.d_date_sk
WHERE d_return.d_current_year = '2023'
  AND s.s_state = 'CA'
  AND t.t_am_pm = 'PM'
GROUP BY
    d_return.d_current_year,
    d_return.d_quarter_name,
    d_closed.d_current_quarter,
    s.s_state,
    s.s_city
HAVING SUM(sr.sr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
