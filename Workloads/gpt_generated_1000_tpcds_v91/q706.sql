SELECT
    cs.cs_order_number AS order_number,
    cs.cs_ext_sales_price AS ext_sales_price,
    cs.cs_quantity,
    i.i_item_id,
    i.i_brand,
    cp.cp_department,
    ca_bill.ca_state AS bill_state,
    ca_ship.ca_state AS ship_state,
    CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_status,
    RANK() OVER (PARTITION BY cp.cp_department ORDER BY cs.cs_ext_sales_price DESC) AS dept_sales_rank
FROM tpcds.catalog_sales cs
JOIN tpcds.catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN tpcds.customer_address ca_bill
  ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN tpcds.customer_address ca_ship
  ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
WHERE cs.cs_ext_sales_price > 5000
  AND i.i_brand = 'Brand#12'
  AND cp.cp_catalog_page_number IN (7, 18, 21)
  AND ca_bill.ca_suite_number = 'Suite 100'

UNION

SELECT
    cs.cs_order_number AS order_number,
    cs.cs_ext_sales_price AS ext_sales_price,
    cs.cs_quantity,
    i.i_item_id,
    i.i_brand,
    cp.cp_department,
    ca_bill.ca_state AS bill_state,
    ca_ship.ca_state AS ship_state,
    CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_status,
    RANK() OVER (PARTITION BY cp.cp_department ORDER BY cs.cs_ext_sales_price DESC) AS dept_sales_rank
FROM tpcds.catalog_sales cs
JOIN tpcds.catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN tpcds.customer_address ca_bill
  ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN tpcds.customer_address ca_ship
  ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
WHERE cs.cs_ext_sales_price > 5000
  AND i.i_brand = 'Brand#34'
  AND cp.cp_catalog_page_number IN (2, 9, 18)
  AND ca_ship.ca_suite_number = 'Suite B'

ORDER BY dept_sales_rank, order_number
LIMIT 100
