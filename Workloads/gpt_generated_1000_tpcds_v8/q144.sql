WITH orders_excluding AS (
    SELECT cs1.cs_order_number
    FROM catalog_sales cs1
    JOIN date_dim d1 ON cs1.cs_sold_date_sk = d1.d_date_sk
    WHERE d1.d_year = 2020
    EXCEPT
    SELECT cs2.cs_order_number
    FROM catalog_sales cs2
    JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2021
)
SELECT
    cp.cp_type,
    w.w_warehouse_name,
    d_sold.d_year,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(DISTINCT cs.cs_order_number) AS order_count
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN inventory inv ON inv.inv_date_sk = d_sold.d_date_sk
JOIN warehouse w2 ON inv.inv_warehouse_sk = w2.w_warehouse_sk
JOIN orders_excluding oe ON cs.cs_order_number = oe.cs_order_number
WHERE EXISTS (
    SELECT 1
    FROM inventory inv2
    WHERE inv2.inv_item_sk = cs.cs_item_sk
      AND inv2.inv_date_sk = cs.cs_sold_date_sk
      AND inv2.inv_quantity_on_hand > 0
)
GROUP BY cp.cp_type, w.w_warehouse_name, d_sold.d_year
HAVING SUM(cs.cs_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
