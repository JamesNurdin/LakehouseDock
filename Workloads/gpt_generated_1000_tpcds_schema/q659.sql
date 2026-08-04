WITH sales_union AS (
    SELECT ss.ss_sold_date_sk AS date_sk,
           ss.ss_ext_sales_price AS sales_amount,
           'store' AS source,
           ss.ss_customer_sk AS cust_sk,
           ss.ss_store_sk AS store_sk
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2001
    )
    UNION DISTINCT
    SELECT ws.ws_sold_date_sk AS date_sk,
           ws.ws_ext_sales_price AS sales_amount,
           'web' AS source,
           ws.ws_bill_customer_sk AS cust_sk,
           NULL AS store_sk
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2001
    )
)
SELECT
    d.d_date,
    su.source,
    COUNT(DISTINCT su.cust_sk) AS distinct_customers,
    SUM(su.sales_amount) AS total_sales,
    CASE
        WHEN su.source = 'store' THEN SUM(su.sales_amount) * 0.9
        ELSE SUM(su.sales_amount) * 0.95
    END AS adjusted_sales,
    (
        SELECT COUNT(*)
        FROM web_returns wr
        WHERE wr.wr_refunded_customer_sk = cu.c_customer_sk
    ) AS customer_return_count,
    st.s_store_name,
    ws2.web_name,
    cp.cp_description,
    r.r_reason_desc
FROM sales_union su
JOIN date_dim d ON su.date_sk = d.d_date_sk
LEFT JOIN store_sales ss ON su.source = 'store' 
    AND ss.ss_customer_sk = su.cust_sk 
    AND ss.ss_sold_date_sk = su.date_sk
LEFT JOIN web_sales ws ON su.source = 'web' 
    AND ws.ws_bill_customer_sk = su.cust_sk 
    AND ws.ws_sold_date_sk = su.date_sk
FULL OUTER JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
FULL OUTER JOIN catalog_page cp ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
LEFT JOIN reason r ON r.r_reason_sk = cr.cr_reason_sk
LEFT JOIN customer cu ON cu.c_customer_sk = su.cust_sk
LEFT JOIN household_demographics hd ON hd.hd_demo_sk = cu.c_current_hdemo_sk
LEFT JOIN store st ON st.s_store_sk = ss.ss_store_sk
LEFT JOIN web_site ws2 ON ws2.web_site_sk = ws.ws_web_site_sk
LEFT JOIN inventory i ON i.inv_date_sk = d.d_date_sk
LEFT JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
WHERE (
        su.source = 'store' AND ss.ss_store_sk IN (SELECT s_store_sk FROM store WHERE s_state = 'TX')
    )
    OR su.source = 'web'
    AND cp.cp_department = 'electronics'
    AND hd.hd_income_band_sk BETWEEN 5 AND 8
    AND d.d_month_seq = 1222
    AND i.inv_quantity_on_hand > 0
GROUP BY
    d.d_date,
    su.source,
    st.s_store_name,
    ws2.web_name,
    cp.cp_description,
    r.r_reason_desc,
    cu.c_customer_sk
ORDER BY total_sales DESC
LIMIT 100
