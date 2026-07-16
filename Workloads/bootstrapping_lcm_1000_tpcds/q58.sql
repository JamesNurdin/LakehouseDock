SELECT
    ws.web_site_id,
    ws.web_name,
    s.s_store_id,
    s.s_store_name,
    s.s_city AS store_city,
    d_ret.d_year AS return_year,
    d_ret.d_quarter_name AS return_quarter,
    COUNT(*) AS return_count,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_tax) AS total_return_tax,
    AVG(wr.wr_return_amt) AS avg_return_amount,
    wp.wp_url,
    d_creation.d_year AS page_creation_year,
    d_access.d_year AS page_access_year,
    d_close.d_year AS site_close_year
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_creation
    ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_ret.d_date_sk
JOIN date_dim d_close
    ON ws.web_close_date_sk = d_close.d_date_sk
WHERE d_ret.d_year >= 2018
GROUP BY
    ws.web_site_id,
    ws.web_name,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    d_ret.d_year,
    d_ret.d_quarter_name,
    wp.wp_url,
    d_creation.d_year,
    d_access.d_year,
    d_close.d_year
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
