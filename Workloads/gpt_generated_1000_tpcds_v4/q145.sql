WITH
    -- Alias the date dimension for clarity (same table reused via multiple joins)
    d_sales AS (SELECT * FROM date_dim)
SELECT
    d_sales.d_year AS sales_year,
    i1.i_category AS category,
    cc1.cc_name AS call_center_name,
    ws1.web_name AS website_name,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    AVG(hd1.hd_vehicle_count) AS avg_vehicle_count,
    SUM(hd2.hd_dep_count) AS total_dep_count,
    MIN(i2.i_current_price) AS min_item_price,
    MAX(i2.i_current_price) AS max_item_price
FROM store_sales ss
JOIN d_sales d_sales
  ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN item i1
  ON ss.ss_item_sk = i1.i_item_sk
JOIN item i2
  ON ss.ss_item_sk = i2.i_item_sk
JOIN household_demographics hd1
  ON ss.ss_hdemo_sk = hd1.hd_demo_sk
JOIN household_demographics hd2
  ON ss.ss_hdemo_sk = hd2.hd_demo_sk
JOIN call_center cc1
  ON cc1.cc_open_date_sk = d_sales.d_date_sk
JOIN call_center cc2
  ON cc2.cc_closed_date_sk = d_sales.d_date_sk
JOIN web_site ws1
  ON ws1.web_open_date_sk = d_sales.d_date_sk
JOIN web_site ws2
  ON ws2.web_close_date_sk = d_sales.d_date_sk
WHERE d_sales.d_year BETWEEN 1999 AND 2001
  AND i1.i_category = 'Sports'
GROUP BY
    d_sales.d_year,
    i1.i_category,
    cc1.cc_name,
    ws1.web_name
ORDER BY total_sales DESC
LIMIT 100
