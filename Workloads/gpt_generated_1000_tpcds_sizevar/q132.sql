SELECT
    s.s_store_name,
    i.i_category,
    cp.cp_department,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    AVG(ss.ss_sales_price) AS avg_store_price,
    MIN(cs.cs_sales_price) AS min_catalog_price,
    MAX(ss.ss_sales_price) AS max_store_price
FROM catalog_sales cs
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN time_dim td1 ON cs.cs_sold_time_sk = td1.t_time_sk
JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p2 ON ss.ss_promo_sk = p2.p_promo_sk
JOIN customer_demographics cd2 ON ss.ss_cdemo_sk = cd2.cd_demo_sk
JOIN customer_address ca2 ON ss.ss_addr_sk = ca2.ca_address_sk
JOIN time_dim td2 ON ss.ss_sold_time_sk = td2.t_time_sk
JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
WHERE c.c_birth_year = 1964
  AND s.s_tax_percentage = 0.05
  AND td1.t_hour = 15
  AND cs.cs_order_number NOT IN (
        SELECT ss2.ss_ticket_number
        FROM store_sales ss2
        WHERE ss2.ss_quantity > 100
    )
GROUP BY s.s_store_name, i.i_category, cp.cp_department
ORDER BY total_catalog_sales DESC
LIMIT 100
