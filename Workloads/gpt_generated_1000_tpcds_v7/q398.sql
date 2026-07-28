WITH
    d_sales AS (
        SELECT *
        FROM date_dim
        WHERE d_year = 2000
    ),
    d_ship AS (
        SELECT *
        FROM date_dim
        WHERE d_year = 2000
    ),
    d_inventory AS (
        SELECT *
        FROM date_dim
        WHERE d_year = 2000
    )
SELECT
    w_cat.w_warehouse_name,
    cc.cc_name,
    pc.p_promo_name               AS catalog_promo,
    pc2.p_promo_name              AS store_promo,
    ws.web_name,
    d_sales.d_year                 AS sales_year,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    SUM(cs.cs_ext_sales_price)          AS catalog_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_orders,
    SUM(ss.ss_ext_sales_price)          AS store_sales,
    SUM(cs.cs_ext_sales_price) + SUM(ss.ss_ext_sales_price) AS total_sales
FROM catalog_sales cs
JOIN d_sales        d_sales      ON cs.cs_sold_date_sk = d_sales.d_date_sk
JOIN d_ship         d_ship       ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN call_center    cc           ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page   cp           ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion      pc           ON cs.cs_promo_sk = pc.p_promo_sk
JOIN warehouse      w_cat        ON cs.cs_warehouse_sk = w_cat.w_warehouse_sk
JOIN customer_address ca_bill    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN inventory      inv          ON inv.inv_warehouse_sk = w_cat.w_warehouse_sk
JOIN d_inventory    d_inventory  ON inv.inv_date_sk = d_inventory.d_date_sk
JOIN web_site       ws           ON ws.web_open_date_sk = d_sales.d_date_sk
JOIN store_sales    ss           ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN promotion      pc2          ON ss.ss_promo_sk = pc2.p_promo_sk
JOIN customer_address ca_store   ON ss.ss_addr_sk = ca_store.ca_address_sk
GROUP BY
    w_cat.w_warehouse_name,
    cc.cc_name,
    pc.p_promo_name,
    pc2.p_promo_name,
    ws.web_name,
    d_sales.d_year
ORDER BY total_sales DESC
LIMIT 100
