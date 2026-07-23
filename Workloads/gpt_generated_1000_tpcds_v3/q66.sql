SELECT
    cp.cp_catalog_page_number,
    i.i_brand,
    w.w_state,
    cd.cd_gender,
    SUM(cs.cs_ext_sales_price) + SUM(ss.ss_ext_sales_price) + SUM(ws.ws_ext_sales_price) AS total_ext_sales_price,
    SUM(cs.cs_quantity) + SUM(ss.ss_quantity) + SUM(ws.ws_quantity) AS total_quantity,
    (SUM(cs.cs_ext_discount_amt) + SUM(ss.ss_ext_discount_amt) + SUM(ws.ws_ext_discount_amt)) / NULLIF(SUM(cs.cs_quantity) + SUM(ss.ss_quantity) + SUM(ws.ws_quantity), 0) AS avg_discount,
    COUNT(DISTINCT cs.cs_order_number) + COUNT(DISTINCT ss.ss_ticket_number) + COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    GREATEST(MAX(cs.cs_net_profit), MAX(ss.ss_net_profit), MAX(ws.ws_net_profit)) AS max_net_profit
FROM catalog_sales cs
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    AND ss.ss_customer_sk = c.c_customer_sk
    AND ss.ss_cdemo_sk = cd.cd_demo_sk
    AND ss.ss_hdemo_sk = hd.hd_demo_sk
LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    AND ws.ws_bill_customer_sk = c.c_customer_sk
    AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE
    cs.cs_wholesale_cost > 30.00
    AND cs.cs_ext_list_price < 20000.00
    AND cs.cs_coupon_amt BETWEEN 500 AND 1100
    AND cp.cp_catalog_page_number IN (10, 12, 15)
    AND c.c_current_cdemo_sk IN (1660663, 93662, 475745)
    AND c.c_first_shipto_date_sk > 2450000
    AND i.i_brand_id = 1
    AND w.w_state = 'CA'
    AND wp.wp_type = 'home'
GROUP BY
    cp.cp_catalog_page_number,
    i.i_brand,
    w.w_state,
    cd.cd_gender
HAVING
    (SUM(cs.cs_ext_sales_price) + SUM(ss.ss_ext_sales_price) + SUM(ws.ws_ext_sales_price)) > 100000
    AND (COUNT(DISTINCT cs.cs_order_number) + COUNT(DISTINCT ss.ss_ticket_number) + COUNT(DISTINCT ws.ws_order_number)) > 10
ORDER BY total_ext_sales_price DESC
LIMIT 100
