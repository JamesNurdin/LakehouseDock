-- Goal: Identify high‑value orders that appear in both store and catalog sales for the year 2001, enrich them with customer, item, store, call‑center and web information, rank them by total store sales, and illustrate a cross‑joined grouping set.
WITH intersect_orders AS (
    SELECT ss.ss_ticket_number AS order_id
    FROM store_sales ss
    JOIN date_dim d1 ON ss.ss_sold_date_sk = d1.d_date_sk
    WHERE d1.d_year = 2001
    INTERSECT
    SELECT cs.cs_order_number AS order_id
    FROM catalog_sales cs
    JOIN date_dim d2 ON cs.cs_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
)
SELECT
    io.order_id,
    d.d_year,
    i.i_category,
    i.i_brand,
    c.c_first_name,
    c.c_last_name,
    s.s_store_name,
    cc.cc_name,
    wp.wp_url,
    g.grp,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    CASE WHEN SUM(ss.ss_ext_sales_price) > 0 THEN 'Store' ELSE 'Other' END AS top_source,
    RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS store_sales_rank,
    ROW_NUMBER() OVER (ORDER BY io.order_id) AS row_num
FROM intersect_orders io
CROSS JOIN (SELECT 1 AS grp UNION ALL SELECT 2 AS grp) g
JOIN store_sales ss ON ss.ss_ticket_number = io.order_id
JOIN catalog_sales cs ON cs.cs_order_number = io.order_id
JOIN web_sales ws ON ws.ws_order_number = io.order_id
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
WHERE
    i.i_category = 'Sports'
    AND hd.hd_vehicle_count >= 1
    AND ca.ca_state = 'CA'
    AND t.t_hour BETWEEN 8 AND 18
    AND wp.wp_type = 'Content'
    AND d.d_month_seq BETWEEN 1200 AND 1300
GROUP BY
    io.order_id,
    d.d_year,
    i.i_category,
    i.i_brand,
    c.c_first_name,
    c.c_last_name,
    s.s_store_name,
    cc.cc_name,
    wp.wp_url,
    g.grp
ORDER BY store_sales_rank
LIMIT 100
