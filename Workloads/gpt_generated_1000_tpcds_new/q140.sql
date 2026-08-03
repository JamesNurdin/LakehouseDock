WITH base AS (
    SELECT
        d.d_date,
        d.d_year,
        s.s_store_name,
        s.s_state,
        c.c_customer_id,
        c.c_preferred_cust_flag,
        cp.cp_department,
        sm.sm_type,
        ws.web_name,
        cs.cs_net_paid,
        ss.ss_store_sk,
        d.d_date_sk
    FROM date_dim d
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    FULL OUTER JOIN store_returns sr
        ON sr.sr_store_sk = s.s_store_sk
       AND sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND c.c_preferred_cust_flag = 'Y'
      AND cp.cp_department = 'Electronics'
      AND sm.sm_type = 'AIR'
      AND ws.web_name LIKE '%Online%'
)
SELECT
    d_date,
    s_store_name,
    c_customer_id,
    cp_department,
    sm_type,
    web_name,
    l.store_sales_today,
    SUM(cs_net_paid)               AS catalog_sales_today,
    l.store_sales_today + SUM(cs_net_paid) AS total_sales,
    RANK() OVER (PARTITION BY s_state ORDER BY l.store_sales_today + SUM(cs_net_paid) DESC) AS state_sales_rank
FROM base
CROSS JOIN LATERAL (
    SELECT SUM(ss2.ss_net_paid) AS store_sales_today
    FROM store_sales ss2
    WHERE ss2.ss_store_sk = ss_store_sk
      AND ss2.ss_sold_date_sk = d_date_sk
) l
GROUP BY
    d_date,
    s_store_name,
    s_state,
    c_customer_id,
    cp_department,
    sm_type,
    web_name,
    l.store_sales_today
ORDER BY total_sales DESC
LIMIT 100
