SELECT
    cc.cc_company_name,
    cc.cc_market_manager,
    cc.cc_city,
    s.s_store_name,
    s.s_state,
    CASE WHEN s.s_floor_space > 5000 THEN 'Large' ELSE 'Small' END AS floor_space_category,
    d.d_year AS return_year,
    d.d_month_seq AS return_month_seq,
    d_cc_open.d_year AS cc_open_year,
    COUNT(*) AS total_returns,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_net_loss) AS total_net_loss,
    SUM(sr.sr_return_quantity) AS total_return_quantity,
    SUM(sr.sr_return_amt) / NULLIF(SUM(sr.sr_return_quantity), 0) AS avg_return_amount_per_qty,
    AVG(wp.wp_image_count) AS avg_image_count,
    SUM(CASE WHEN wp.wp_type = 'article' THEN 1 ELSE 0 END) AS article_page_count,
    SUM(CASE WHEN wp.wp_type = 'video' THEN 1 ELSE 0 END) AS video_page_count
FROM date_dim d
JOIN call_center cc
    ON cc.cc_closed_date_sk = d.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
   AND sr.sr_store_sk = s.s_store_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
   AND wp.wp_access_date_sk = d.d_date_sk
WHERE d.d_year >= 2000
GROUP BY
    cc.cc_company_name,
    cc.cc_market_manager,
    cc.cc_city,
    s.s_store_name,
    s.s_state,
    CASE WHEN s.s_floor_space > 5000 THEN 'Large' ELSE 'Small' END,
    d.d_year,
    d.d_month_seq,
    d_cc_open.d_year
HAVING SUM(sr.sr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
