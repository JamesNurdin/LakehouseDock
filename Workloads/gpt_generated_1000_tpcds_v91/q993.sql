SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    cc.cc_name AS call_center_name,
    cp.cp_catalog_number,
    d_sold.d_year,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_quantity) AS total_quantity,
    AVG(cs.cs_list_price) AS avg_list_price,
    CASE
        WHEN SUM(cs.cs_net_profit) > (SELECT avg(cs_net_profit) FROM catalog_sales) THEN 'Above Avg Profit'
        ELSE 'Below Avg Profit'
    END AS profit_category,
    (SELECT SUM(cs2.cs_quantity)
        FROM catalog_sales cs2
        WHERE cs2.cs_item_sk = i.i_item_sk) AS total_qty_for_item
FROM catalog_sales cs
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer c_bill
    ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer c_ship
    ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d_inv
    ON inv.inv_date_sk = d_inv.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c_bill.c_customer_sk
JOIN date_dim d_page
    ON wp.wp_creation_date_sk = d_page.d_date_sk
WHERE d_sold.d_date >= DATE '2001-01-01'
  AND d_sold.d_date <= DATE '2001-12-31'
GROUP BY
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    cc.cc_name,
    cp.cp_catalog_number,
    d_sold.d_year,
    i.i_item_sk
ORDER BY total_sales DESC
LIMIT 100
