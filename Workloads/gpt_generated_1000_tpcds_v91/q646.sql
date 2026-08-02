-- Goal: Analyze catalog sales that did NOT have a return, broken down by call center, year, and item brand, with various aggregates and selective filters.
WITH non_returned_orders AS (
    SELECT cs.cs_order_number
    FROM tpcds.catalog_sales cs
    EXCEPT
    SELECT cr.cr_order_number
    FROM tpcds.catalog_returns cr
)
SELECT
    cc.cc_name,
    d.d_year,
    i.i_brand,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    COUNT(DISTINCT i.i_item_sk) AS distinct_items_sold,
    SUM(cs.cs_net_paid) AS total_sales,
    AVG(ss.ss_net_profit) AS avg_store_profit,
    SUM(inv.inv_quantity_on_hand) AS total_inventory,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_web_pages
FROM tpcds.catalog_sales cs
JOIN tpcds.date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN tpcds.time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
JOIN tpcds.item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN tpcds.promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN tpcds.call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN tpcds.household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
LEFT JOIN tpcds.store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
   AND ss.ss_sold_date_sk = d.d_date_sk
   AND ss.ss_sold_time_sk = t.t_time_sk
   AND ss.ss_customer_sk = c.c_customer_sk
   AND ss.ss_hdemo_sk = hd.hd_demo_sk
   AND ss.ss_addr_sk = ca.ca_address_sk
   AND ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN tpcds.inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_date_sk = d.d_date_sk
   AND inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN tpcds.catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
LEFT JOIN tpcds.reason r
    ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN tpcds.web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN non_returned_orders nro
    ON cs.cs_order_number = nro.cs_order_number
WHERE
    d.d_year = 2001
    AND i.i_brand = 'Brand#45'
    AND p.p_channel_catalog = 'N'
    AND wp.wp_autogen_flag = 'Y'
    AND ss.ss_net_profit > 0
    AND inv.inv_quantity_on_hand > 1000
GROUP BY
    cc.cc_name,
    d.d_year,
    i.i_brand
ORDER BY
    total_sales DESC
LIMIT 100
