WITH filtered_data AS (
    SELECT
        d.d_fy_year,
        d.d_date,
        COALESCE(c.c_customer_sk, c2.c_customer_sk) AS customer_sk,
        c.c_first_name,
        c.c_last_name,
        s.s_store_name,
        cc.cc_name,
        w.w_warehouse_name,
        cp.cp_description,
        r.r_reason_desc,
        ss.ss_net_paid,
        cs.cs_net_paid
    FROM tpcds.date_dim d
    LEFT JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    FULL OUTER JOIN tpcds.store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN tpcds.customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN tpcds.catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN tpcds.customer c2
        ON cs.cs_bill_customer_sk = c2.c_customer_sk
    LEFT JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN tpcds.catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN tpcds.reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN tpcds.web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_fy_year = 1904
      AND d.d_moy IN (4, 7, 11)
      AND cp.cp_catalog_page_id = 'AAAAAAAACAAAAAAA'
      AND cc.cc_employees > 50
      AND w.w_warehouse_sq_ft > 50000
      AND r.r_reason_id = 'AAAAAAAABAAAAAAA'
      AND NOT EXISTS (
          SELECT 1
          FROM tpcds.catalog_returns cr2
          WHERE cr2.cr_refunded_customer_sk = COALESCE(c.c_customer_sk, c2.c_customer_sk)
      )
),
agg AS (
    SELECT
        customer_sk,
        c_first_name,
        c_last_name,
        s_store_name,
        cc_name,
        w_warehouse_name,
        cp_description,
        r_reason_desc,
        SUM(COALESCE(ss_net_paid, 0)) AS total_store_net_paid,
        SUM(COALESCE(cs_net_paid, 0)) AS total_catalog_net_paid,
        SUM(COALESCE(ss_net_paid, 0) + COALESCE(cs_net_paid, 0)) AS total_combined_net_paid,
        MAX(d_fy_year) AS fy_year,
        MAX(d_date) AS last_date
    FROM filtered_data
    GROUP BY
        customer_sk,
        c_first_name,
        c_last_name,
        s_store_name,
        cc_name,
        w_warehouse_name,
        cp_description,
        r_reason_desc
)
SELECT
    customer_sk,
    c_first_name,
    c_last_name,
    s_store_name,
    cc_name,
    w_warehouse_name,
    cp_description,
    r_reason_desc,
    total_store_net_paid,
    total_catalog_net_paid,
    total_combined_net_paid,
    ROW_NUMBER() OVER (PARTITION BY fy_year ORDER BY total_combined_net_paid DESC) AS fy_customer_rank,
    CASE
        WHEN total_combined_net_paid > (SELECT AVG(total_combined_net_paid) FROM agg) THEN 'High'
        ELSE 'Low'
    END AS spending_category,
    AVG(total_combined_net_paid) OVER (PARTITION BY fy_year ORDER BY last_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3_days
FROM agg
ORDER BY total_combined_net_paid DESC
LIMIT 100
