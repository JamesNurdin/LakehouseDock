SELECT
    s.s_store_id,
    s.s_state,
    dr_return.d_year,
    dr_return.d_month_seq,
    t.t_hour,
    wp.wp_type,
    COUNT(DISTINCT sr.sr_ticket_number) AS total_tickets,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_return_quantity) AS avg_return_quantity,
    SUM(wp.wp_image_count) AS total_image_count,
    SUM(wp.wp_link_count) AS total_link_count,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages
FROM store_returns sr
JOIN date_dim dr_return
    ON sr.sr_returned_date_sk = dr_return.d_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim dc_closed
    ON s.s_closed_date_sk = dc_closed.d_date_sk
JOIN time_dim t
    ON sr.sr_return_time_sk = t.t_time_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = dr_return.d_date_sk
JOIN date_dim dac_access
    ON wp.wp_access_date_sk = dac_access.d_date_sk
GROUP BY ROLLUP (s.s_store_id, s.s_state, dr_return.d_year, dr_return.d_month_seq, t.t_hour, wp.wp_type)
HAVING SUM(sr.sr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
