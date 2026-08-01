WITH ticket_without_return AS (
    SELECT ss_ticket_number
    FROM store_sales
    EXCEPT
    SELECT sr_ticket_number
    FROM store_returns
),
overall_avg_net AS (
    SELECT AVG(cs_net_paid_inc_tax) AS overall_avg_net_paid_inc_tax
    FROM catalog_sales
),
joined_data AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_ext_sales_price AS store_sales_ext_sales_price,
        cs.cs_quantity AS catalog_quantity,
        cs.cs_ext_sales_price AS catalog_sales_ext_sales_price,
        cs.cs_net_paid_inc_tax AS cs_net_paid_inc_tax,
        cs.cs_ext_ship_cost AS cs_ext_ship_cost,
        w.w_warehouse_sq_ft,
        w.w_city,
        sm.sm_type,
        cp.cp_department,
        c.c_customer_sk,
        c.c_birth_year,
        d_sales.d_year,
        d_sales.d_month_seq,
        d_sales.d_date,
        r.r_reason_desc,
        wr.wr_return_amt,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM store_sales ss
    JOIN ticket_without_return twr ON ss.ss_ticket_number = twr.ss_ticket_number
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales ON ss.ss_sold_time_sk = t_sales.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
        AND sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
    LEFT JOIN time_dim t_return ON sr.sr_return_time_sk = t_return.t_time_sk
    LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    LEFT JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        AND wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN date_dim d_web_return ON wr.wr_returned_date_sk = d_web_return.d_date_sk
    LEFT JOIN time_dim t_web_return ON wr.wr_returned_time_sk = t_web_return.t_time_sk
    LEFT JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    LEFT JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    LEFT JOIN web_site ws ON d_wp_creation.d_date_sk = ws.web_open_date_sk
    LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = d_sales.d_date_sk
        AND cs.cs_bill_customer_sk = c.c_customer_sk
        AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    LEFT JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    LEFT JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    LEFT JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    LEFT JOIN date_dim d_ws_open ON ws.web_open_date_sk = d_ws_open.d_date_sk
    LEFT JOIN date_dim d_ws_close ON ws.web_close_date_sk = d_ws_close.d_date_sk
    WHERE
        d_sales.d_year = 2001
        AND d_sales.d_month_seq = 12
        AND c.c_birth_year = 1975
        AND w.w_warehouse_sq_ft > 500000
        AND sm.sm_type = 'AIR'
        AND cs.cs_ext_sales_price > 500
),
aggregated AS (
    SELECT
        jd.d_year,
        jd.cp_department,
        jd.sm_type,
        jd.w_city,
        COUNT(DISTINCT jd.c_customer_sk) AS unique_customers,
        SUM(jd.catalog_sales_ext_sales_price) AS total_catalog_sales,
        SUM(jd.store_sales_ext_sales_price) AS total_store_sales,
        SUM(jd.wr_return_amt) AS total_web_return_amount,
        AVG(jd.cs_net_paid_inc_tax) AS avg_catalog_net_paid_inc_tax,
        MIN(jd.cs_ext_ship_cost) AS min_ship_cost,
        MAX(jd.cs_ext_ship_cost) AS max_ship_cost,
        overall_avg_net.overall_avg_net_paid_inc_tax,
        -- correlated scalar subquery: total catalog sales for the same year
        (SELECT SUM(cs2.cs_ext_sales_price)
         FROM catalog_sales cs2
         JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
         WHERE d2.d_year = jd.d_year) AS total_catalog_sales_year,
        -- correlated scalar subquery: total returns for customers born in 1975 in the same year
        (SELECT COUNT(*)
         FROM store_returns sr2
         JOIN date_dim d2 ON sr2.sr_returned_date_sk = d2.d_date_sk
         JOIN customer c2 ON sr2.sr_customer_sk = c2.c_customer_sk
         WHERE d2.d_year = jd.d_year
           AND c2.c_birth_year = 1975) AS returns_for_birth_year
    FROM joined_data jd
    CROSS JOIN overall_avg_net
    GROUP BY
        jd.d_year,
        jd.cp_department,
        jd.sm_type,
        jd.w_city,
        overall_avg_net.overall_avg_net_paid_inc_tax
)
SELECT
    d_year,
    cp_department,
    sm_type,
    w_city,
    unique_customers,
    total_catalog_sales,
    total_store_sales,
    total_web_return_amount,
    avg_catalog_net_paid_inc_tax,
    min_ship_cost,
    max_ship_cost,
    overall_avg_net_paid_inc_tax,
    total_catalog_sales_year,
    returns_for_birth_year,
    RANK() OVER (ORDER BY total_catalog_sales DESC) AS sales_rank,
    SUM(total_catalog_sales) OVER (PARTITION BY d_year) AS catalog_sales_by_year
FROM aggregated
ORDER BY total_catalog_sales DESC
LIMIT 100
