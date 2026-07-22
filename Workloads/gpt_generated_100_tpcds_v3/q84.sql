WITH overall_avg AS (
    SELECT AVG(ss2.ss_net_paid) AS avg_net_paid
    FROM store_sales ss2
    JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
    WHERE d2.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-01-31'
)
SELECT
    s.s_store_name,
    cp.cp_type,
    d_sales.d_date,
    td.t_hour,
    r.r_reason_desc,
    ws.web_name,
    wp.wp_url,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(sr.sr_return_amt) AS total_returns,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_sales,
    COUNT(DISTINCT sr.sr_ticket_number) AS num_returns,
    AVG(ss.ss_net_profit) AS avg_net_profit,
    (SELECT avg_net_paid FROM overall_avg) AS overall_avg_net_paid
FROM store_sales ss
JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_store_sk = s.s_store_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = d_sales.d_date_sk
JOIN date_dim d_catalog ON cp.cp_end_date_sk = d_catalog.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d_sales.d_date_sk
JOIN date_dim d_site ON ws.web_close_date_sk = d_site.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_sales.d_date_sk
JOIN date_dim d_page ON wp.wp_access_date_sk = d_page.d_date_sk
WHERE s.s_state = 'CA'
  AND r.r_reason_desc = 'Did not like the model'
  AND ws.web_manager = 'James Austin'
  AND wp.wp_image_count > 3
  AND d_sales.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-01-31'
GROUP BY
    s.s_store_name,
    cp.cp_type,
    d_sales.d_date,
    td.t_hour,
    r.r_reason_desc,
    ws.web_name,
    wp.wp_url
ORDER BY total_sales DESC
LIMIT 100
