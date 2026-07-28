WITH sales AS (
        SELECT 
            cs.cs_sold_date_sk,
            cs.cs_order_number,
            cs.cs_item_sk,
            cs.cs_quantity,
            cs.cs_ext_sales_price,
            cs.cs_net_profit,
            cs.cs_call_center_sk,
            cs.cs_catalog_page_sk,
            cs.cs_warehouse_sk,
            cs.cs_bill_customer_sk,
            cs.cs_bill_addr_sk
        FROM catalog_sales cs
        WHERE cs.cs_quantity > 5
          AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2450500
    ),
    returns AS (
        SELECT 
            cr.cr_order_number,
            cr.cr_return_quantity,
            cr.cr_return_amount,
            cr.cr_reason_sk,
            cr.cr_warehouse_sk,
            cr.cr_returned_date_sk,
            cr.cr_reversed_charge
        FROM catalog_returns cr
        WHERE cr.cr_reversed_charge > 100
          AND cr.cr_return_quantity > 0
    )
SELECT
    w.w_city AS warehouse_city,
    r.r_reason_desc AS return_reason,
    s.s_store_name AS store_name,
    ws.ws_quantity AS web_quantity,
    SUM(sa.cs_ext_sales_price) AS total_catalog_sales,
    SUM(rt.cr_return_amount) AS total_returns_amount,
    SUM(sa.cs_net_profit) - SUM(rt.cr_return_amount) AS net_profit_after_returns,
    COUNT(DISTINCT sa.cs_order_number) AS distinct_orders,
    MIN(sa.cs_sold_date_sk) AS min_sales_date_sk,
    MAX(sa.cs_sold_date_sk) AS max_sales_date_sk
FROM sales sa
JOIN returns rt ON rt.cr_order_number = sa.cs_order_number
JOIN item i ON i.i_item_sk = sa.cs_item_sk
JOIN warehouse w ON w.w_warehouse_sk = sa.cs_warehouse_sk
JOIN call_center cc ON cc.cc_call_center_sk = sa.cs_call_center_sk
JOIN catalog_page cp ON cp.cp_catalog_page_sk = sa.cs_catalog_page_sk
JOIN reason r ON r.r_reason_sk = rt.cr_reason_sk
JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
JOIN store s ON s.s_store_sk = ss.ss_store_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN web_site we ON we.web_site_sk = ws.ws_web_site_sk
JOIN customer c ON c.c_customer_sk = sa.cs_bill_customer_sk
JOIN customer_address ca ON ca.ca_address_sk = sa.cs_bill_addr_sk
WHERE cc.cc_name = 'Call Center 1'
  AND cp.cp_type = 'A'
  AND w.w_city IN ('Pleasant Grove', 'Salem')
  AND r.r_reason_id = 'AAAAAAAABBAAAAAA'
  AND we.web_name = 'Online Store'
GROUP BY
    w.w_city,
    r.r_reason_desc,
    s.s_store_name,
    ws.ws_quantity
ORDER BY total_catalog_sales DESC
LIMIT 100
