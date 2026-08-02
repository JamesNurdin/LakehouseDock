WITH RECURSIVE time_hierarchy (t_time_sk, lvl) AS (
    SELECT t_time_sk, 1 AS lvl
    FROM time_dim
    WHERE t_time_sk = (SELECT MIN(t_time_sk) FROM time_dim)
    UNION ALL
    SELECT td.t_time_sk, th.lvl + 1
    FROM time_hierarchy th
    JOIN time_dim td ON td.t_time_sk = th.t_time_sk + 1
    WHERE th.lvl < 5
)
SELECT
    cp.cp_department,
    cp.cp_catalog_page_number,
    i.i_category,
    i.i_brand,
    w.w_state,
    td.t_shift,
    td.t_am_pm,
    time_hierarchy.lvl AS time_level,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    COUNT(DISTINCT i.i_item_id) AS distinct_items,
    SUM(cs.cs_net_paid) AS total_sales,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    MIN(cs.cs_net_profit) AS min_profit,
    MAX(cs.cs_net_profit) AS max_profit,
    SUM(COALESCE(cr.cr_net_loss, 0)) AS total_return_loss,
    SUM(ss.ss_ext_discount_amt) AS total_store_discount,
    SUM(ws.ws_ext_discount_amt) AS total_web_discount
FROM catalog_sales cs
JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
JOIN time_hierarchy ON td.t_time_sk = time_hierarchy.t_time_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number AND cs.cs_item_sk = cr.cr_item_sk
LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN store_sales ss ON ss.ss_sold_time_sk = td.t_time_sk
    AND ss.ss_item_sk = i.i_item_sk
    AND ss.ss_customer_sk = c.c_customer_sk
    AND ss.ss_addr_sk = ca.ca_address_sk
JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
    AND ws.ws_item_sk = i.i_item_sk
    AND ws.ws_bill_customer_sk = c.c_customer_sk
    AND ws.ws_bill_addr_sk = ca.ca_address_sk
WHERE
    td.t_am_pm = 'PM'
    AND td.t_shift = 'second'
    AND cp.cp_catalog_page_number IN (12, 14)
    AND i.i_current_price > 100
    AND w.w_state = 'CA'
GROUP BY GROUPING SETS (
    (cp.cp_department, cp.cp_catalog_page_number, i.i_category, i.i_brand, w.w_state, td.t_shift, td.t_am_pm, time_hierarchy.lvl),
    (cp.cp_department, i.i_category, w.w_state, td.t_shift, time_hierarchy.lvl),
    (cp.cp_department, w.w_state, td.t_shift),
    (cp.cp_department, w.w_state),
    (cp.cp_department)
)
ORDER BY total_sales DESC
LIMIT 100
