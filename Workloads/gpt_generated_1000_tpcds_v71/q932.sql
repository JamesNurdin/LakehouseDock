WITH agg_data AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        td.t_hour,
        cc.cc_name            AS call_center_name,
        s.s_store_name,
        SUM(cs.cs_net_paid)   AS total_sales,
        SUM(cr.cr_return_amount) AS total_catalog_returns,
        SUM(sr.sr_return_amt)    AS total_store_returns,
        COUNT(DISTINCT cs.cs_order_number) AS num_orders,
        MAX(wp.wp_url)        AS any_page_url
    FROM time_dim td
    JOIN catalog_sales cs
      ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_returned_time_sk = td.t_time_sk
     AND cr.cr_call_center_sk   = cc.cc_call_center_sk
    LEFT JOIN reason r_cr
      ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN store_returns sr
      ON sr.sr_return_time_sk = td.t_time_sk
     AND sr.sr_customer_sk    = c.c_customer_sk
    LEFT JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN reason r_sr
      ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN web_page wp
      ON wp.wp_customer_sk = c.c_customer_sk
    WHERE c.c_birth_month = 5
      AND td.t_hour BETWEEN 9 AND 17
      AND cc.cc_state = 'CA'
    GROUP BY GROUPING SETS (
        (c.c_customer_sk, c.c_first_name, c.c_last_name, td.t_hour, cc.cc_name, s.s_store_name),
        (c.c_customer_sk, c.c_first_name, c.c_last_name, td.t_hour, cc.cc_name),
        (c.c_customer_sk, c.c_first_name, c.c_last_name, td.t_hour),
        (c.c_customer_sk, c.c_first_name, c.c_last_name)
    )
)
SELECT
    c_customer_sk,
    c_first_name,
    c_last_name,
    t_hour,
    call_center_name,
    s_store_name,
    total_sales,
    total_catalog_returns,
    total_store_returns,
    num_orders,
    any_page_url,
    RANK() OVER (PARTITION BY c_customer_sk ORDER BY total_sales DESC) AS sales_rank,
    CASE
        WHEN total_sales > 10000 THEN 'High'
        WHEN total_sales > 5000  THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM agg_data
WHERE total_sales IS NOT NULL
ORDER BY total_sales DESC
LIMIT 100
