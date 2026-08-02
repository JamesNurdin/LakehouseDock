WITH
    s1 AS (
        SELECT cs.cs_order_number
        FROM catalog_sales cs
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        WHERE cp.cp_catalog_number = 2
    ),
    s2 AS (
        SELECT cs.cs_order_number
        FROM catalog_sales cs
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        WHERE sm.sm_contract = 'GNJr3g5i7oorKqtX'
    ),
    intersect_orders AS (
        SELECT cs_order_number FROM s1
        INTERSECT
        SELECT cs_order_number FROM s2
    ),
    agg_sales AS (
        SELECT
            cs.cs_sold_date_sk,
            sm.sm_type,
            cp.cp_department,
            sum(cs.cs_ext_sales_price) AS total_sales,
            sum(cs.cs_net_profit) AS total_profit,
            grouping(cs.cs_sold_date_sk) AS g_date,
            grouping(sm.sm_type) AS g_type,
            grouping(cp.cp_department) AS g_dept
        FROM catalog_sales cs
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2459999
        GROUP BY GROUPING SETS (
            (cs.cs_sold_date_sk, sm.sm_type, cp.cp_department),
            (cs.cs_sold_date_sk, sm.sm_type),
            (cs.cs_sold_date_sk, cp.cp_department),
            (sm.sm_type, cp.cp_department),
            (cs.cs_sold_date_sk),
            (sm.sm_type),
            (cp.cp_department),
            ()
        )
    ),
    base_items AS (
        SELECT
            i.i_item_sk,
            i.i_brand,
            i.i_category,
            i.i_current_price
        FROM item i
        WHERE i.i_rec_start_date <= DATE '2000-01-01'
          AND i.i_rec_end_date > DATE '2000-01-01'
    )
SELECT
    a.cs_sold_date_sk,
    a.sm_type,
    a.cp_department,
    a.total_sales,
    a.total_profit,
    i.i_brand,
    i.i_category,
    (SELECT avg(cs2.cs_ext_sales_price)
     FROM catalog_sales cs2
     WHERE cs2.cs_item_sk = i.i_item_sk) AS avg_item_sales_price,
    (SELECT count(*)
     FROM intersect_orders io
     WHERE io.cs_order_number = cs.cs_order_number) AS intersect_order_count
FROM agg_sales a
JOIN catalog_sales cs ON a.cs_sold_date_sk = cs.cs_sold_date_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN base_items i ON cs.cs_item_sk = i.i_item_sk
WHERE EXISTS (
    SELECT 1
    FROM intersect_orders io
    WHERE io.cs_order_number = cs.cs_order_number
)
UNION
SELECT
    a2.cs_sold_date_sk,
    a2.sm_type,
    a2.cp_department,
    a2.total_sales,
    a2.total_profit,
    bi.i_brand,
    bi.i_category,
    NULL AS avg_item_sales_price,
    0 AS intersect_order_count
FROM agg_sales a2
JOIN catalog_sales cs2 ON a2.cs_sold_date_sk = cs2.cs_sold_date_sk
JOIN ship_mode sm2 ON cs2.cs_ship_mode_sk = sm2.sm_ship_mode_sk
JOIN catalog_page cp2 ON cs2.cs_catalog_page_sk = cp2.cp_catalog_page_sk
JOIN base_items bi ON cs2.cs_item_sk = bi.i_item_sk
WHERE cs2.cs_quantity > (
    SELECT avg(cs3.cs_quantity)
    FROM catalog_sales cs3
    WHERE cs3.cs_item_sk = bi.i_item_sk
)
AND cs2.cs_order_number IN (SELECT cs_order_number FROM intersect_orders)
ORDER BY total_sales DESC
LIMIT 100
