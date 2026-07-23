SELECT
    cc.cc_name,
    cp.cp_department,
    d.d_year,
    ca.ca_state,
    i.inv_warehouse_sk,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT cs.cs_order_number) AS order_count,
    MIN(cs.cs_ext_tax) AS min_tax,
    MAX(cs.cs_ext_list_price) AS max_list_price,
    SUM(i.inv_quantity_on_hand) AS total_quantity_on_hand
FROM tpcds.catalog_sales cs
JOIN tpcds.call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.customer_address ca
  ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN tpcds.date_dim d
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN tpcds.inventory i
  ON i.inv_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND cc.cc_state = 'CA'
  AND cp.cp_department = 'Electronics'
  AND i.inv_warehouse_sk IN (10, 18)
  AND cs.cs_ext_list_price > 1000.00
  AND ca.ca_state = 'TX'
GROUP BY cc.cc_name, cp.cp_department, d.d_year, ca.ca_state, i.inv_warehouse_sk
ORDER BY total_net_paid DESC
LIMIT 100
