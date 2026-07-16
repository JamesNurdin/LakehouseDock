SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    ws.web_site_id,
    ws.web_name,
    ws.web_city,
    ws.web_state,
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month,
    COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
    SUM(sr.sr_return_amt) AS sum_return_amount,
    AVG(sr.sr_return_amt) AS avg_return_amount,
    SUM(sr.sr_return_quantity) AS total_return_quantity,
    SUM(sr.sr_return_tax) AS total_return_tax,
    SUM(wp.wp_image_count) AS total_images,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
    MAX(wp.wp_max_ad_count) AS max_ad_count,
    d_site_close.d_year AS site_close_year,
    d_store_close.d_year AS store_closed_year,
    d_page_access.d_year AS page_access_year
FROM store_returns sr
JOIN date_dim d_ret
  ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN store s
  ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_store_close
  ON s.s_closed_date_sk = d_store_close.d_date_sk
JOIN web_site ws
  ON ws.web_open_date_sk = d_ret.d_date_sk
JOIN date_dim d_site_close
  ON ws.web_close_date_sk = d_site_close.d_date_sk
JOIN web_page wp
  ON wp.wp_creation_date_sk = d_site_close.d_date_sk
JOIN date_dim d_page_access
  ON wp.wp_access_date_sk = d_page_access.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    ws.web_site_id,
    ws.web_name,
    ws.web_city,
    ws.web_state,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_site_close.d_year,
    d_store_close.d_year,
    d_page_access.d_year
ORDER BY sum_return_amount DESC
LIMIT 100
