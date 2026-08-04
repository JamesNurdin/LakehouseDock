WITH base AS (
    SELECT
        d.d_year,
        s.s_division_name,
        sm.sm_type,
        cs.cs_ext_sales_price,
        ws.ws_ext_sales_price,
        c.c_customer_id,
        c.c_customer_sk,
        cs.cs_quantity,
        ws.ws_net_paid
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN tpcds.customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.catalog_sales cs
        ON cs.cs_bill_customer_sk = c.c_customer_sk
        AND cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND cp.cp_department = 'Books'
      AND cs.cs_quantity > 5
      AND ws.ws_net_paid > 1000
),
store_customers AS (
    SELECT DISTINCT c_customer_id
    FROM base
    WHERE cs_ext_sales_price > 5000
),
web_customers AS (
    SELECT DISTINCT c_customer_id
    FROM base
    WHERE ws_ext_sales_price > 5000
)
SELECT
    b.s_division_name,
    b.sm_type,
    SUM(b.cs_ext_sales_price) AS total_catalog_sales,
    SUM(b.ws_ext_sales_price) AS total_web_sales,
    COUNT(DISTINCT b.c_customer_id) AS customer_cnt
FROM base b
WHERE b.c_customer_id IN (
    SELECT c_customer_id FROM store_customers
    EXCEPT
    SELECT c_customer_id FROM web_customers
)
GROUP BY b.s_division_name, b.sm_type
ORDER BY total_catalog_sales DESC
