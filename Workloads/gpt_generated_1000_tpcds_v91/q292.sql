WITH categories_low_wholesale AS (
    SELECT i.i_category
    FROM item i
    WHERE i.i_wholesale_cost < 5
),
categories_active_promo AS (
    SELECT i.i_category
    FROM promotion p
    JOIN item i ON p.p_item_sk = i.i_item_sk
    WHERE p.p_discount_active = 'Y'
),
target_categories AS (
    SELECT i_category FROM categories_low_wholesale
    INTERSECT
    SELECT i_category FROM categories_active_promo
),
base_data AS (
    SELECT
        cs.cs_order_number,
        d_sold.d_year AS sales_year,
        d_ship.d_year AS ship_year,
        i.i_category,
        i.i_product_name,
        w.w_warehouse_name,
        cc.cc_name,
        cp.cp_catalog_number,
        p.p_promo_name,
        t.t_hour,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        inv.inv_quantity_on_hand,
        latest_inv.latest_qty
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN web_page wp ON c_bill.c_customer_sk = wp.wp_customer_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    CROSS JOIN LATERAL (
        SELECT inv2.inv_quantity_on_hand AS latest_qty
        FROM inventory inv2
        WHERE inv2.inv_item_sk = i.i_item_sk
          AND inv2.inv_warehouse_sk = w.w_warehouse_sk
        ORDER BY inv2.inv_date_sk DESC
        LIMIT 1
    ) AS latest_inv
    WHERE i.i_category IN (SELECT i_category FROM target_categories)
      AND cs.cs_net_paid > 0
      AND NOT EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_item_sk = i.i_item_sk
            AND p2.p_promo_sk <> p.p_promo_sk
      )
),
agg_data AS (
    SELECT
        sales_year,
        i_category,
        i_product_name,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_paid) AS total_sales,
        SUM(cs_net_profit) AS total_profit,
        AVG(latest_qty) AS avg_latest_inventory_qty
    FROM base_data
    GROUP BY sales_year, i_category, i_product_name
)
SELECT
    sales_year,
    i_category,
    i_product_name,
    total_quantity,
    total_sales,
    total_profit,
    avg_latest_inventory_qty,
    RANK() OVER (PARTITION BY sales_year ORDER BY total_profit DESC) AS profit_rank,
    SUM(total_sales) OVER (PARTITION BY sales_year) AS sales_year_total
FROM agg_data
ORDER BY sales_year, profit_rank
LIMIT 100
