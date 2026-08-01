SELECT
    cp.cp_department,
    i.i_brand,
    td.t_hour,
    w.w_state,
    SUM(cs.cs_net_paid) AS total_catalog_net_paid,
    SUM(ws.ws_net_paid) AS total_web_net_paid,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
    AVG(i.i_current_price) AS avg_item_price,
    MIN(cs.cs_sales_price) AS min_catalog_sales_price,
    MAX(ws.ws_sales_price) AS max_web_sales_price
FROM
    catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_time_sk = td.t_time_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
        AND ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
    JOIN customer_address ca_ws_ship ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
    JOIN customer_demographics cd_ws_bill ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
    JOIN customer_demographics cd_ws_ship ON ws.ws_ship_cdemo_sk = cd_ws_ship.cd_demo_sk
WHERE
    cp.cp_department = 'Books'
    AND td.t_hour BETWEEN 9 AND 11
    AND i.i_brand = 'Brand#45'
    AND ca_bill.ca_city = 'New Hope'
    AND p.p_discount_active = 'Y'
    AND cs.cs_sales_price > 100
    AND ws.ws_sales_price > 100
    AND cs.cs_item_sk IN (
        SELECT cs_sub.cs_item_sk
        FROM catalog_sales cs_sub
        WHERE cs_sub.cs_sales_price > 100
        INTERSECT
        SELECT ws_sub.ws_item_sk
        FROM web_sales ws_sub
        WHERE ws_sub.ws_sales_price > 100
    )
GROUP BY
    ROLLUP (cp.cp_department, i.i_brand, td.t_hour, w.w_state)
ORDER BY
    total_catalog_net_paid DESC
LIMIT 100
