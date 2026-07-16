SELECT
    cc.cc_name AS call_center_name,
    s.s_store_name,
    d.d_year,
    CASE WHEN d.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END AS half_year,
    SUM(sr.sr_net_loss) AS total_net_loss,
    SUM(sr.sr_return_quantity) AS total_return_quantity,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_return_tickets,
    AVG(sr.sr_return_amt) AS avg_return_amount,
    SUM(CASE WHEN sr.sr_return_quantity > 1 THEN sr.sr_net_loss ELSE 0 END) AS net_loss_multi_item,
    SUM(wp.wp_image_count) AS total_image_count,
    SUM(wp.wp_link_count) AS total_link_count,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages,
    AVG(CASE WHEN wp.wp_autogen_flag = 'Y' THEN wp.wp_char_count END) AS avg_autogen_char_count,
    SUM(CASE WHEN d.d_quarter_name = 'Q1' THEN sr.sr_net_loss ELSE 0 END) AS q1_net_loss,
    SUM(CASE WHEN d.d_quarter_name = 'Q2' THEN sr.sr_net_loss ELSE 0 END) AS q2_net_loss,
    SUM(CASE WHEN d.d_quarter_name = 'Q3' THEN sr.sr_net_loss ELSE 0 END) AS q3_net_loss,
    SUM(CASE WHEN d.d_quarter_name = 'Q4' THEN sr.sr_net_loss ELSE 0 END) AS q4_net_loss
FROM
    date_dim d
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON s.s_store_sk = sr.sr_store_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE
    sr.sr_return_quantity > 0
GROUP BY
    cc.cc_name,
    s.s_store_name,
    d.d_year,
    CASE WHEN d.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END
HAVING
    SUM(sr.sr_net_loss) > 0
ORDER BY
    total_net_loss DESC
LIMIT 100
