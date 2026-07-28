SELECT
    i.i_category,
    d_sold.d_year AS sales_year,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(cs.cs_quantity) AS total_quantity,
    CASE
        WHEN SUM(cs.cs_ext_discount_amt) > 10000 THEN 'HIGH_DISCOUNT'
        ELSE 'LOW_DISCOUNT'
    END AS discount_level,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    AVG(i.i_current_price) AS avg_item_price,
    MIN(ca_bill.ca_state) AS billing_state,
    MAX(ws_open.web_name) AS open_site_name,
    MAX(ws_close.web_name) AS close_site_name
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
LEFT JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
LEFT JOIN customer_demographics cd_ship
    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
LEFT JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
LEFT JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN inventory inv
    ON cs.cs_item_sk = inv.inv_item_sk
   AND cs.cs_warehouse_sk = inv.inv_warehouse_sk
JOIN date_dim d_inv
    ON inv.inv_date_sk = d_inv.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN web_site ws_open
    ON ws_open.web_open_date_sk = d_sold.d_date_sk
LEFT JOIN web_site ws_close
    ON ws_close.web_close_date_sk = d_ship.d_date_sk
GROUP BY
    i.i_category,
    d_sold.d_year
ORDER BY total_sales DESC
LIMIT 100
