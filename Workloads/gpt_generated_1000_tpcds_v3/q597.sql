SELECT
    d_sales.d_year,
    cc.cc_name,
    cp.cp_department,
    ws.web_name,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
    AVG(cs.cs_quantity) AS avg_catalog_quantity,
    MIN(cs.cs_ext_sales_price) AS min_catalog_price,
    MAX(ss.ss_ext_sales_price) AS max_store_price,
    (
        SELECT MAX(cs2.cs_ext_sales_price)
        FROM catalog_sales cs2
        JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = d_sales.d_year
    ) AS max_yearly_catalog_price
FROM catalog_sales cs
JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_cp ON cp.cp_start_date_sk = d_cp.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d_sales.d_date_sk
JOIN inventory i ON i.inv_date_sk = d_sales.d_date_sk
JOIN store_sales ss ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN customer_address ca_store ON ss.ss_addr_sk = ca_store.ca_address_sk
JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer_demographics cd_store ON ss.ss_cdemo_sk = cd_store.cd_demo_sk
JOIN household_demographics hd_store ON ss.ss_hdemo_sk = hd_store.hd_demo_sk
WHERE d_sales.d_year = 2000
  AND cc.cc_state = 'CA'
  AND ws.web_market_manager = 'Edward George'
  AND cp.cp_department = 'Sports'
  AND cs.cs_ext_sales_price > 1000
  AND cs.cs_bill_customer_sk IN (
        SELECT DISTINCT cs2.cs_bill_customer_sk
        FROM catalog_sales cs2
        WHERE cs2.cs_ext_sales_price > 5000
    )
GROUP BY
    d_sales.d_year,
    cc.cc_name,
    cp.cp_department,
    ws.web_name
ORDER BY total_catalog_sales DESC
LIMIT 100
