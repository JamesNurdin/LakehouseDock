WITH sub1 AS (
    SELECT
        cs.cs_order_number,
        w.w_warehouse_id,
        sm.sm_ship_mode_id,
        i.i_category,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_item_sk) AS distinct_items
    FROM catalog_sales cs
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer cu ON cs.cs_bill_customer_sk = cu.c_customer_sk
    WHERE w.w_country = 'United States'
      AND w.w_city IN ('Pine Grove', 'Riverside')
      AND sm.sm_contract = 'Ek'
      AND sm.sm_code = 'AIR'
      AND i.i_category = 'Electronics'
      AND td.t_hour = 10
      AND cs.cs_quantity > 5
      AND cr.cr_return_quantity > 0
    GROUP BY cs.cs_order_number, w.w_warehouse_id, sm.sm_ship_mode_id, i.i_category
),
sub2 AS (
    SELECT
        cs.cs_order_number,
        w.w_warehouse_id,
        sm.sm_ship_mode_id,
        i.i_category,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_item_sk) AS distinct_items
    FROM catalog_sales cs
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer cu ON cs.cs_bill_customer_sk = cu.c_customer_sk
    WHERE w.w_state = 'CA'
      AND w.w_city = 'Liberty'
      AND sm.sm_contract = 'Xjy3ZPuiDjzHlRx14Z3'
      AND sm.sm_code = 'SURFACE'
      AND i.i_category = 'Furniture'
      AND td.t_hour = 14
      AND cs.cs_quantity > 10
      AND cr.cr_return_quantity > 2
    GROUP BY cs.cs_order_number, w.w_warehouse_id, sm.sm_ship_mode_id, i.i_category
)
SELECT
    u.w_warehouse_id,
    u.sm_ship_mode_id,
    u.i_category,
    SUM(u.total_sales) AS sum_sales,
    AVG(u.total_profit) AS avg_profit,
    COUNT(*) AS order_count
FROM (
    SELECT cs_order_number, w_warehouse_id, sm_ship_mode_id, i_category, total_sales, total_profit, distinct_items FROM sub1
    UNION
    SELECT cs_order_number, w_warehouse_id, sm_ship_mode_id, i_category, total_sales, total_profit, distinct_items FROM sub2
) AS u
JOIN (
    SELECT cs_order_number FROM sub1
    INTERSECT
    SELECT cs_order_number FROM sub2
) AS c ON u.cs_order_number = c.cs_order_number
GROUP BY u.w_warehouse_id, u.sm_ship_mode_id, u.i_category
ORDER BY sum_sales DESC
LIMIT 100
