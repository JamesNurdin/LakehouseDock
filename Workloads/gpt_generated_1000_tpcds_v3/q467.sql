WITH
    ss_agg AS (
        SELECT
            ss_item_sk,
            ss_store_sk,
            ss_sold_date_sk,
            ss_sold_time_sk,
            ss_customer_sk,
            ss_addr_sk,
            SUM(ss_net_paid) AS store_net_paid,
            SUM(ss_quantity) AS store_quantity
        FROM store_sales
        GROUP BY ss_item_sk, ss_store_sk, ss_sold_date_sk, ss_sold_time_sk, ss_customer_sk, ss_addr_sk
    ),
    sr_agg AS (
        SELECT
            sr_item_sk,
            sr_store_sk,
            sr_returned_date_sk,
            sr_return_time_sk,
            SUM(sr_return_amt) AS total_return_amt,
            SUM(sr_return_quantity) AS total_return_quantity
        FROM store_returns
        GROUP BY sr_item_sk, sr_store_sk, sr_returned_date_sk, sr_return_time_sk
    ),
    ws_agg AS (
        SELECT
            ws_item_sk,
            ws_web_site_sk,
            ws_web_page_sk,
            ws_warehouse_sk,
            ws_sold_date_sk,
            ws_sold_time_sk,
            SUM(ws_net_paid) AS total_web_net_paid,
            SUM(ws_quantity) AS total_web_quantity,
            COUNT(DISTINCT ws_bill_customer_sk) AS distinct_web_customers
        FROM web_sales
        GROUP BY ws_item_sk, ws_web_site_sk, ws_web_page_sk, ws_warehouse_sk, ws_sold_date_sk, ws_sold_time_sk
    ),
    distinct_store_customers AS (
        SELECT
            ss_item_sk,
            ss_store_sk,
            COUNT(DISTINCT ss_customer_sk) AS distinct_store_customers
        FROM store_sales
        GROUP BY ss_item_sk, ss_store_sk
    ),
    distinct_web_customers AS (
        SELECT
            ws_item_sk,
            COUNT(DISTINCT ws_bill_customer_sk) AS distinct_web_customers
        FROM web_sales
        GROUP BY ws_item_sk
    ),
    distinct_web_pages AS (
        SELECT DISTINCT
            wp_web_page_sk,
            wp_url
        FROM web_page
    )
SELECT
    i.i_item_id,
    i.i_product_name,
    s.s_store_name,
    d_sales.d_year AS sale_year,
    CASE WHEN SUM(ss.store_net_paid) > 10000 THEN 'High' ELSE 'Low' END AS profit_category,
    SUM(ss.store_net_paid) AS total_store_net_paid,
    SUM(ss.store_quantity) AS total_store_quantity,
    COALESCE(SUM(sr.total_return_amt), 0) AS total_return_amount,
    COALESCE(SUM(sr.total_return_quantity), 0) AS total_return_quantity,
    COALESCE(SUM(ws.total_web_net_paid), 0) AS total_web_net_paid,
    COALESCE(SUM(ws.total_web_quantity), 0) AS total_web_quantity,
    MAX(d_closed.d_year) AS store_closed_year,
    MAX(w.w_warehouse_name) AS warehouse_name,
    MAX(dp.wp_url) AS web_page_url,
    MAX(d_open.d_year) AS web_site_open_year,
    MAX(d_page_creation.d_year) AS page_creation_year,
    MAX(d_page_access.d_year) AS page_access_year,
    MAX(t_sales.t_am_pm) AS store_sales_time_am_pm,
    MAX(t_web_sales.t_am_pm) AS web_sales_time_am_pm,
    MAX(d_return.d_year) AS last_return_year,
    MAX(t_return_time.t_am_pm) AS return_time_am_pm,
    MAX(d_cust_first_sales.d_year) AS cust_first_sales_year,
    MAX(ds.distinct_store_customers) AS distinct_store_customers,
    MAX(ds2.distinct_web_customers) AS distinct_web_customers
FROM ss_agg ss
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t_sales
    ON ss.ss_sold_time_sk = t_sales.t_time_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
LEFT JOIN sr_agg sr
    ON ss.ss_item_sk = sr.sr_item_sk
   AND ss.ss_store_sk = sr.sr_store_sk
LEFT JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
LEFT JOIN time_dim t_return_time
    ON sr.sr_return_time_sk = t_return_time.t_time_sk
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
LEFT JOIN ws_agg ws
    ON ss.ss_item_sk = ws.ws_item_sk
LEFT JOIN date_dim d_web_sold
    ON ws.ws_sold_date_sk = d_web_sold.d_date_sk
LEFT JOIN time_dim t_web_sales
    ON ws.ws_sold_time_sk = t_web_sales.t_time_sk
LEFT JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
LEFT JOIN date_dim d_open
    ON ws_site.web_open_date_sk = d_open.d_date_sk
LEFT JOIN date_dim d_site_close
    ON ws_site.web_close_date_sk = d_site_close.d_date_sk
LEFT JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN distinct_web_pages dp
    ON ws.ws_web_page_sk = dp.wp_web_page_sk
LEFT JOIN web_page wp
    ON dp.wp_web_page_sk = wp.wp_web_page_sk
LEFT JOIN date_dim d_page_creation
    ON wp.wp_creation_date_sk = d_page_creation.d_date_sk
LEFT JOIN date_dim d_page_access
    ON wp.wp_access_date_sk = d_page_access.d_date_sk
LEFT JOIN date_dim d_cust_first_sales
    ON c.c_first_sales_date_sk = d_cust_first_sales.d_date_sk
LEFT JOIN distinct_store_customers ds
    ON ss.ss_item_sk = ds.ss_item_sk
   AND ss.ss_store_sk = ds.ss_store_sk
LEFT JOIN distinct_web_customers ds2
    ON ws.ws_item_sk = ds2.ws_item_sk
GROUP BY
    i.i_item_id,
    i.i_product_name,
    s.s_store_name,
    d_sales.d_year
HAVING SUM(ss.store_net_paid) > 5000
ORDER BY total_store_net_paid DESC
LIMIT 100
