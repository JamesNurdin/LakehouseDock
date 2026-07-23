WITH store_agg AS (
    SELECT
        d_sold.d_year AS year,
        d_sold.d_month_seq AS month_seq,
        cp.cp_department AS department,
        t_store.t_hour AS hour,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_paid) AS total_net_paid,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_transactions,
        MIN(ss.ss_sales_price) AS min_sales_price,
        MAX(ss.ss_sales_price) AS max_sales_price
    FROM store_sales ss
    JOIN date_dim d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_store ON ss.ss_sold_time_sk = t_store.t_time_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 1998
      AND t_store.t_am_pm = 'PM'
      AND ss.ss_sales_price > 50.00
      AND cp.cp_catalog_number > 1000
    GROUP BY d_sold.d_year, d_sold.d_month_seq, cp.cp_department, t_store.t_hour
),
web_agg AS (
    SELECT
        d_ws_sold.d_year AS year,
        d_ws_sold.d_month_seq AS month_seq,
        cp.cp_department AS department,
        t_web.t_hour AS hour,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_paid) AS total_net_paid,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_transactions,
        MIN(ws.ws_sales_price) AS min_sales_price,
        MAX(ws.ws_sales_price) AS max_sales_price
    FROM web_sales ws
    JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN time_dim t_web ON ws.ws_sold_time_sk = t_web.t_time_sk
    JOIN catalog_page cp ON cp.cp_end_date_sk = d_ws_sold.d_date_sk
    WHERE d_ws_sold.d_year = 1998
      AND t_web.t_am_pm = 'PM'
      AND ws.ws_ext_tax < 200.00
      AND cp.cp_catalog_page_number < 50
    GROUP BY d_ws_sold.d_year, d_ws_sold.d_month_seq, cp.cp_department, t_web.t_hour
)
SELECT
    year,
    month_seq,
    department,
    hour,
    total_sales,
    total_net_paid,
    avg_sales_price,
    distinct_transactions,
    min_sales_price,
    max_sales_price
FROM store_agg
UNION ALL
SELECT
    year,
    month_seq,
    department,
    hour,
    total_sales,
    total_net_paid,
    avg_sales_price,
    distinct_transactions,
    min_sales_price,
    max_sales_price
FROM web_agg
ORDER BY year, month_seq, department, hour
