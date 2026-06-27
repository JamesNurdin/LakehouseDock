SELECT
    wsit.web_name,
    cp.cp_department,
    d_sold.d_year,
    sum(ws.ws_net_profit) AS total_profit,
    sum(ws.ws_ext_sales_price) AS total_sales,
    count(*) AS order_count
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN web_site wsit
    ON ws.ws_web_site_sk = wsit.web_site_sk
JOIN date_dim d_open
    ON wsit.web_open_date_sk = d_open.d_date_sk
JOIN date_dim d_close
    ON wsit.web_close_date_sk = d_close.d_date_sk
JOIN catalog_page cp
    ON cp.cp_department IS NOT NULL
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
WHERE d_sold.d_date >= d_open.d_date
  AND d_sold.d_date <= d_close.d_date
  AND d_sold.d_date >= d_cp_start.d_date
  AND d_sold.d_date <= d_cp_end.d_date
  AND d_sold.d_year = 2001
GROUP BY wsit.web_name, cp.cp_department, d_sold.d_year
ORDER BY total_profit DESC
LIMIT 10
