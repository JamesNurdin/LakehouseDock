WITH sales_metrics AS (
    SELECT
        cs.cs_order_number                                     AS order_number,
        w.w_warehouse_name                                    AS warehouse_name,
        i.i_product_name                                      AS product_name,
        cs.cs_net_paid_inc_ship                               AS primary_val,
        cs.cs_quantity                                        AS secondary_val,
        ARRAY[cs.cs_net_paid_inc_ship, cs.cs_quantity]        AS metrics
    FROM catalog_sales cs
    JOIN warehouse w   ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i        ON cs.cs_item_sk = i.i_item_sk
    WHERE w.w_county = 'Richland County'
      AND cs.cs_net_paid_inc_ship > 3000
),
sales_expanded AS (
    SELECT
        s.order_number,
        s.warehouse_name,
        s.product_name,
        s.primary_val,
        s.secondary_val,
        u.metric,
        u.idx
    FROM sales_metrics s
    CROSS JOIN LATERAL (
        SELECT metric, idx
        FROM UNNEST(s.metrics) WITH ORDINALITY AS t(metric, idx)
    ) u
),
inventory_metrics AS (
    SELECT
        cs.cs_order_number                                     AS order_number,
        w.w_warehouse_name                                    AS warehouse_name,
        i.i_product_name                                      AS product_name,
        inv.inv_quantity_on_hand                              AS primary_val,
        cs.cs_ext_ship_cost                                   AS secondary_val,
        ARRAY[inv.inv_quantity_on_hand, cs.cs_ext_ship_cost] AS metrics
    FROM catalog_sales cs
    JOIN inventory inv ON cs.cs_item_sk = inv.inv_item_sk
    JOIN warehouse w   ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN item i        ON inv.inv_item_sk = i.i_item_sk
    WHERE inv.inv_quantity_on_hand > 500
      AND w.w_state = 'CA'
),
inventory_expanded AS (
    SELECT
        i.order_number,
        i.warehouse_name,
        i.product_name,
        i.primary_val,
        i.secondary_val,
        u.metric,
        u.idx
    FROM inventory_metrics i
    CROSS JOIN LATERAL (
        SELECT metric, idx
        FROM UNNEST(i.metrics) WITH ORDINALITY AS t(metric, idx)
    ) u
)
SELECT *
FROM sales_expanded
UNION ALL
SELECT *
FROM inventory_expanded
ORDER BY metric DESC
LIMIT 100
