WITH sales_by_page AS (
    SELECT
        cs.cs_catalog_page_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    GROUP BY cs.cs_catalog_page_sk
)
SELECT
    cp.cp_catalog_page_id,
    cp.cp_department,
    d_sold.d_year,
    w.w_state,
    sm.sm_type,
    SUM(cs.cs_ext_sales_price) AS day_sales,
    SUM(cs.cs_net_profit) AS day_profit,
    SUM(CASE WHEN w.w_state = 'NY' THEN cs.cs_net_profit ELSE 0 END) AS ny_profit,
    (
        SELECT SUM(cs2.cs_ext_sales_price)
        FROM catalog_sales cs2
        JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = d_sold.d_year
    ) AS total_year_sales,
    sales_by_page.total_sales AS page_total_sales,
    sales_by_page.total_profit AS page_total_profit
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_sold.d_date_sk
JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN sales_by_page ON sales_by_page.cs_catalog_page_sk = cs.cs_catalog_page_sk
WHERE d_sold.d_year = 1998
  AND w.w_state IN ('NY', 'CA')
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_department,
    d_sold.d_year,
    w.w_state,
    sm.sm_type,
    sales_by_page.total_sales,
    sales_by_page.total_profit
ORDER BY day_sales DESC
LIMIT 100
