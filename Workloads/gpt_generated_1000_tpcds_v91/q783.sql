WITH ss_agg AS (
    SELECT
        ss_customer_sk,
        ss_sold_date_sk,
        SUM(ss_net_paid) AS total_net_paid,
        COUNT(*) AS sales_txn_count,
        AVG(ss_quantity) AS avg_quantity
    FROM store_sales
    GROUP BY ss_customer_sk, ss_sold_date_sk
),
unioned AS (
    SELECT
        c.c_customer_id AS customer_id,
        d_sales.d_date AS sale_date,
        cp.cp_catalog_number AS catalog_number,
        w.w_warehouse_name AS warehouse_name,
        ss_agg.total_net_paid AS sales_amount,
        cr.cr_return_amount AS catalog_return_amount,
        wr.wr_return_amt AS web_return_amount,
        (SELECT COUNT(*) FROM store_sales ss2 WHERE ss2.ss_customer_sk = c.c_customer_sk AND ss2.ss_sold_date_sk = d_sales.d_date_sk) AS daily_sales_txn_count,
        t.addr_part AS address_attribute
    FROM ss_agg
    JOIN date_dim d_sales ON ss_agg.ss_sold_date_sk = d_sales.d_date_sk
    JOIN customer c ON ss_agg.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    CROSS JOIN LATERAL (SELECT ARRAY[ca.ca_state, ca.ca_country] AS address_array) AS la
    CROSS JOIN UNNEST(la.address_array) AS t (addr_part)
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d_sales.d_date_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d_sales.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_sales.d_date_sk
    JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    JOIN date_dim d_ws_close ON ws.web_close_date_sk = d_ws_close.d_date_sk
    WHERE
        d_sales.d_year = 2020
        AND d_sales.d_month_seq BETWEEN 240 AND 250
        AND cp.cp_catalog_number = 8
        AND cp.cp_type = 'C'
        AND w.w_state = 'CA'
        AND c.c_preferred_cust_flag = 'Y'
        AND ca.ca_country = 'USA'
        AND ss_agg.total_net_paid > 1000
        AND cr.cr_return_quantity > 0
        AND d_sales.d_date >= DATE '2020-01-01'
        AND d_sales.d_date <= DATE '2020-12-31'

    UNION

    SELECT
        c.c_customer_id AS customer_id,
        d_sales2.d_date AS sale_date,
        cp2.cp_catalog_number AS catalog_number,
        w2.w_warehouse_name AS warehouse_name,
        ss_agg2.total_net_paid AS sales_amount,
        cr2.cr_return_amount AS catalog_return_amount,
        wr2.wr_return_amt AS web_return_amount,
        (SELECT COUNT(*) FROM store_sales ss2b WHERE ss2b.ss_customer_sk = c.c_customer_sk AND ss2b.ss_sold_date_sk = d_sales2.d_date_sk) AS daily_sales_txn_count,
        t2.addr_part AS address_attribute
    FROM ss_agg AS ss_agg2
    JOIN date_dim d_sales2 ON ss_agg2.ss_sold_date_sk = d_sales2.d_date_sk
    JOIN customer c ON ss_agg2.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    CROSS JOIN LATERAL (SELECT ARRAY[ca.ca_state, ca.ca_country] AS address_array) AS la2
    CROSS JOIN UNNEST(la2.address_array) AS t2 (addr_part)
    JOIN catalog_returns cr2 ON cr2.cr_returned_date_sk = d_sales2.d_date_sk
    JOIN catalog_page cp2 ON cr2.cr_catalog_page_sk = cp2.cp_catalog_page_sk
    JOIN warehouse w2 ON cr2.cr_warehouse_sk = w2.w_warehouse_sk
    JOIN web_returns wr2 ON wr2.wr_returned_date_sk = d_sales2.d_date_sk
    JOIN web_site ws2 ON ws2.web_open_date_sk = d_sales2.d_date_sk
    JOIN date_dim d_cp_start2 ON cp2.cp_start_date_sk = d_cp_start2.d_date_sk
    JOIN date_dim d_cp_end2 ON cp2.cp_end_date_sk = d_cp_end2.d_date_sk
    JOIN date_dim d_ws_close2 ON ws2.web_close_date_sk = d_ws_close2.d_date_sk
    WHERE
        d_sales2.d_year = 2020
        AND d_sales2.d_month_seq BETWEEN 240 AND 250
        AND cp2.cp_catalog_number = 8
        AND cp2.cp_type = 'D'
        AND w2.w_state = 'NY'
        AND c.c_preferred_cust_flag = 'Y'
        AND ca.ca_country = 'USA'
        AND ss_agg2.total_net_paid > 1000
        AND cr2.cr_return_quantity > 0
        AND d_sales2.d_date >= DATE '2020-01-01'
        AND d_sales2.d_date <= DATE '2020-12-31'
)
SELECT
    u.customer_id,
    u.sale_date,
    u.catalog_number,
    u.warehouse_name,
    u.address_attribute,
    SUM(u.sales_amount) AS total_sales,
    SUM(u.catalog_return_amount) AS total_catalog_returns,
    SUM(u.web_return_amount) AS total_web_returns,
    COUNT(DISTINCT u.sales_amount) AS distinct_sales_amounts,
    MIN(u.sales_amount) AS min_sales,
    MAX(u.sales_amount) AS max_sales,
    AVG(u.sales_amount) AS avg_sales,
    SUM(u.daily_sales_txn_count) AS total_daily_txns,
    COUNT(*) AS row_count
FROM unioned u
GROUP BY
    u.customer_id,
    u.sale_date,
    u.catalog_number,
    u.warehouse_name,
    u.address_attribute
HAVING
    SUM(u.sales_amount) > 1000
    AND SUM(u.catalog_return_amount) > 0
ORDER BY total_sales DESC
LIMIT 100
