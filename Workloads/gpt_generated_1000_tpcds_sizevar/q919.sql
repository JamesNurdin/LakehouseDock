WITH
    orders_a AS (
        SELECT cs.cs_order_number
        FROM catalog_sales cs
        WHERE cs.cs_coupon_amt > 1500.00
    ),
    orders_b AS (
        SELECT cr.cr_order_number
        FROM catalog_returns cr
        WHERE cr.cr_return_amount > 0
    ),
    intersect_orders AS (
        SELECT DISTINCT cs_order_number
        FROM orders_a
        INTERSECT
        SELECT DISTINCT cr_order_number
        FROM orders_b
    ),
    cs_base AS (
        SELECT
            cs.cs_order_number,
            cs.cs_net_paid,
            cs.cs_ext_discount_amt,
            cs.cs_net_profit,
            i.i_brand,
            i.i_category,
            i.i_manager_id,
            i.i_container,
            cp.cp_department,
            cp.cp_catalog_page_number,
            w.w_warehouse_name,
            w.w_state,
            t.t_hour,
            cr.cr_return_amount
        FROM catalog_sales cs
        JOIN catalog_page cp
            ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN warehouse w
            ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN item i
            ON cs.cs_item_sk = i.i_item_sk
        JOIN time_dim t
            ON cs.cs_sold_time_sk = t.t_time_sk
        LEFT JOIN catalog_returns cr
            ON cr.cr_order_number = cs.cs_order_number
            AND cr.cr_item_sk = i.i_item_sk
            AND cr.cr_warehouse_sk = w.w_warehouse_sk
            AND cr.cr_returned_time_sk = t.t_time_sk
        WHERE cs.cs_order_number IN (SELECT cs_order_number FROM intersect_orders)
          AND i.i_manager_id IN (41, 26)
          AND i.i_container = 'Unknown'
          AND cp.cp_catalog_page_number BETWEEN 1 AND 10
          AND cs.cs_coupon_amt > 1000.00
          AND t.t_hour = 14
          AND w.w_state = 'CA'
    ),
    cs_agg AS (
        SELECT
            i_brand,
            i_category,
            w_warehouse_name,
            cp_department,
            t_hour,
            SUM(cs_net_paid) AS total_net_paid,
            SUM(cs_ext_discount_amt) AS total_discount,
            SUM(cs_net_profit) AS total_profit,
            SUM(cr_return_amount) AS total_return_amount,
            COUNT(DISTINCT cs_order_number) AS distinct_orders
        FROM cs_base
        GROUP BY CUBE (i_brand, i_category, w_warehouse_name, cp_department, t_hour)
    ),
    ss_base AS (
        SELECT
            ss.ss_ticket_number,
            ss.ss_net_paid,
            ss.ss_sales_price,
            i.i_brand,
            i.i_category,
            t.t_hour
        FROM store_sales ss
        JOIN item i
            ON ss.ss_item_sk = i.i_item_sk
        JOIN time_dim t
            ON ss.ss_sold_time_sk = t.t_time_sk
        WHERE ss.ss_quantity > 0
          AND i.i_manager_id = 41
          AND t.t_hour = 14
    ),
    ss_agg AS (
        SELECT
            i_brand,
            i_category,
            t_hour,
            SUM(ss_net_paid) AS store_total_net_paid,
            AVG(ss_sales_price) AS avg_store_price,
            COUNT(DISTINCT ss_ticket_number) AS distinct_tickets
        FROM ss_base
        GROUP BY CUBE (i_brand, i_category, t_hour)
    ),
    full_joined AS (
        SELECT
            COALESCE(cs.i_brand, ss.i_brand) AS brand,
            COALESCE(cs.i_category, ss.i_category) AS category,
            cs.w_warehouse_name,
            cs.cp_department,
            COALESCE(cs.t_hour, ss.t_hour) AS hour,
            cs.total_net_paid,
            cs.total_discount,
            cs.total_profit,
            cs.total_return_amount,
            cs.distinct_orders,
            ss.store_total_net_paid,
            ss.avg_store_price,
            ss.distinct_tickets
        FROM cs_agg cs
        FULL OUTER JOIN ss_agg ss
            ON cs.i_brand = ss.i_brand
            AND cs.i_category = ss.i_category
            AND cs.t_hour = ss.t_hour
    )
SELECT
    brand,
    category,
    w_warehouse_name,
    cp_department,
    hour,
    total_net_paid,
    total_discount,
    total_profit,
    total_return_amount,
    distinct_orders,
    store_total_net_paid,
    avg_store_price,
    distinct_tickets,
    ROW_NUMBER() OVER (PARTITION BY w_warehouse_name ORDER BY total_net_paid DESC) AS warehouse_sales_rank
FROM full_joined
WHERE brand IS NOT NULL
ORDER BY warehouse_sales_rank
LIMIT 100
