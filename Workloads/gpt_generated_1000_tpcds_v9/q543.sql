SELECT
    d.d_year,
    d.d_quarter_seq,
    cp.cp_department,
    cp.cp_catalog_number,
    cs.cs_order_number,
    cs.cs_quantity,
    cs.cs_ext_sales_price,
    cs.cs_net_profit,
    sm.sm_type,
    ca_bill.ca_city AS billing_city,
    ca_ship.ca_city AS shipping_city,
    cd_bill.cd_gender AS billing_gender,
    cd_ship.cd_gender AS shipping_gender,
    r.r_reason_desc AS return_reason,
    wr.wr_return_quantity,
    ws.web_name,
    dept_sales.dept_sales_total,
    SUM(cs.cs_ext_sales_price) OVER (PARTITION BY cp.cp_department) AS total_sales_by_dept,
    RANK() OVER (PARTITION BY cp.cp_department ORDER BY cs.cs_net_profit DESC) AS profit_rank
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
CROSS JOIN LATERAL (
    SELECT SUM(cs2.cs_ext_sales_price) AS dept_sales_total
    FROM catalog_sales cs2
    WHERE cs2.cs_catalog_page_sk = cp.cp_catalog_page_sk
      AND cs2.cs_sold_date_sk = d.d_date_sk
) AS dept_sales
WHERE d.d_year = 1999
  AND d.d_quarter_seq = 10
  AND cp.cp_department = 'Books'
  AND sm.sm_type = 'AIR'
  AND r.r_reason_desc LIKE '%color%'
ORDER BY d.d_year DESC, cp.cp_department, profit_rank
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
