SELECT
    cp.cp_catalog_page_id,
    cp.cp_catalog_page_number,
    cp.cp_department,
    d_start.d_date AS start_date,
    d_end.d_date AS end_date,
    d_sold.d_date AS sold_date,
    d_ship.d_date AS ship_date,
    SUM(cs.cs_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_start_date,
    COUNT(DISTINCT s.s_store_id) AS closed_stores_on_end_date
FROM catalog_page cp
JOIN catalog_sales cs
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN inventory inv
    ON inv.inv_date_sk = d_start.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_end.d_date_sk
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_catalog_page_number,
    cp.cp_department,
    d_start.d_date,
    d_end.d_date,
    d_sold.d_date,
    d_ship.d_date
ORDER BY total_sales DESC
