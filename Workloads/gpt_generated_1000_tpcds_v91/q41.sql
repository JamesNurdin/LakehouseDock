WITH
    inv_agg AS (
        SELECT
            inv_item_sk,
            SUM(inv_quantity_on_hand) AS total_qty_on_hand
        FROM inventory
        WHERE inv_item_sk IN (
            SELECT i_item_sk FROM item WHERE i_brand_id = 6008007
        )
        GROUP BY inv_item_sk
    ),
    sales_agg AS (
        SELECT
            i.i_brand AS i_brand,
            sm.sm_type AS sm_type,
            cp.cp_department AS cp_department,
            td.t_shift AS t_shift,
            SUM(cs.cs_ext_sales_price) AS total_sales,
            SUM(cs.cs_net_profit) AS total_profit,
            COUNT(DISTINCT cs.cs_order_number) AS num_orders,
            SUM(ia.total_qty_on_hand) AS total_qty_on_hand,
            -- correlated subquery: average sales price for the brand across the whole data set
            (SELECT AVG(cs2.cs_ext_sales_price)
             FROM catalog_sales cs2
             JOIN item i2 ON cs2.cs_item_sk = i2.i_item_sk
             WHERE i2.i_brand = i.i_brand) AS avg_brand_sales_price,
            CASE
                WHEN SUM(cs.cs_net_profit) > 100000 THEN 'HIGH'
                WHEN SUM(cs.cs_net_profit) > 50000 THEN 'MEDIUM'
                ELSE 'LOW'
            END AS profit_category
        FROM catalog_sales cs
        JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
        JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
        JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
        JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
        JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk AND p.p_item_sk = i.i_item_sk
        JOIN inv_agg ia ON i.i_item_sk = ia.inv_item_sk
        WHERE
            cs.cs_sold_date_sk BETWEEN 2451050 AND 2451080
            AND i.i_brand_id = 6008007
            AND td.t_shift = 'first'
            AND p.p_discount_active = 'Y'
            AND sm.sm_type = 'AIR'
            AND i.i_manager_id = 25
            AND i.i_item_sk IN (
                SELECT inv_item_sk FROM inventory WHERE inv_quantity_on_hand > 1000
            )
        GROUP BY GROUPING SETS (
                (i.i_brand, sm.sm_type, cp.cp_department, td.t_shift),
                (i.i_brand, sm.sm_type, cp.cp_department),
                (i.i_brand, sm.sm_type),
                (i.i_brand),
                ()
            ),
            i.i_brand,
            sm.sm_type,
            cp.cp_department,
            td.t_shift
    )
SELECT
    i_brand,
    sm_type,
    cp_department,
    t_shift,
    total_sales,
    total_profit,
    profit_category,
    num_orders,
    avg_brand_sales_price,
    total_qty_on_hand,
    RANK() OVER (PARTITION BY i_brand ORDER BY total_sales DESC) AS sales_rank_within_brand
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
