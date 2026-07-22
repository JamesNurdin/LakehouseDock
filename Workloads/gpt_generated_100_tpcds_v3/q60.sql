SELECT
    cc.cc_name AS call_center_name,
    cp.cp_department AS department,
    d_sold.d_year AS year,
    t.t_hour AS hour_of_day,
    s.s_state AS store_state,
    ca.ca_city AS customer_city,
    COUNT(DISTINCT cs.cs_order_number) AS orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_quantity) AS avg_quantity,
    MIN(cs.cs_ext_discount_amt) AS min_discount,
    MAX(cs.cs_ext_discount_amt) AS max_discount
FROM tpcds.catalog_sales cs
JOIN tpcds.date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN tpcds.time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
JOIN tpcds.call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN tpcds.customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN tpcds.store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN tpcds.web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
WHERE
    d_sold.d_year = 2001
    AND d_sold.d_qoy = 2
    AND t.t_hour BETWEEN 9 AND 17
    AND cc.cc_state = 'CA'
    AND ca.ca_state = 'TX'
    AND ca.ca_city = 'Greenville'
    AND cp.cp_department = 'Electronics'
    AND cs.cs_quantity > 5
    AND cs.cs_net_paid > 100
GROUP BY
    cc.cc_name,
    cp.cp_department,
    d_sold.d_year,
    t.t_hour,
    s.s_state,
    ca.ca_city
ORDER BY total_net_paid DESC
LIMIT 100
