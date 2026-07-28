WITH sales_data AS (
    SELECT
        d_ss.d_year,
        i.i_category,
        i.i_current_price,
        w.w_state,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        CASE WHEN ss.ss_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
        c.c_customer_id,
        cs.cs_net_paid_inc_tax,
        r.r_reason_desc
    FROM store_sales ss
    JOIN date_dim d_ss
      ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
      ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN catalog_sales cs
      ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d_cs_sold
      ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
     AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d_inv
      ON inv.inv_date_sk = d_inv.d_date_sk
    LEFT JOIN web_returns wr
      ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN reason r
      ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN date_dim d_wr
      ON wr.wr_returned_date_sk = d_wr.d_date_sk
    LEFT JOIN date_dim d_wp_creation
      ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    LEFT JOIN date_dim d_wp_access
      ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    WHERE d_ss.d_year = 2001
      AND i.i_current_price > 50.00
      AND c.c_birth_year BETWEEN 1950 AND 1965
      AND w.w_city = 'Pine Grove'
      AND cs.cs_net_paid_inc_tax > 1000
)
SELECT
    d_year,
    i_category,
    w_state,
    profit_flag,
    SUM(ss_net_paid) AS total_net_paid,
    AVG(i_current_price) AS avg_item_price,
    COUNT(DISTINCT c_customer_id) AS distinct_customers,
    MIN(ss_quantity) AS min_quantity,
    MAX(ss_quantity) AS max_quantity,
    SUM(CASE WHEN r_reason_desc IS NOT NULL THEN 1 ELSE 0 END) AS returns_count
FROM sales_data
GROUP BY
    d_year,
    i_category,
    w_state,
    profit_flag
ORDER BY total_net_paid DESC
LIMIT 100
