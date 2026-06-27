WITH sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_warehouse_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_order_number
    FROM catalog_sales cs
),
returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_item_sk,
        cr.cr_warehouse_sk,
        cr.cr_order_number,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss
    FROM catalog_returns cr
),
inv_agg AS (
    SELECT
        inv.inv_date_sk,
        inv.inv_item_sk,
        inv.inv_warehouse_sk,
        inv.inv_quantity_on_hand
    FROM inventory inv
)
SELECT
    d.d_year,
    d.d_moy,
    i.i_category,
    w.w_warehouse_name,
    SUM(s.cs_quantity) AS total_units_sold,
    SUM(s.cs_ext_sales_price) AS total_sales_amount,
    SUM(s.cs_net_profit) AS total_net_profit,
    COALESCE(SUM(r.cr_return_quantity), 0) AS total_units_returned,
    COALESCE(SUM(r.cr_return_amount), 0) AS total_return_amount,
    COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS inventory_on_hand_end_of_month
FROM sales s
JOIN date_dim d ON s.cs_sold_date_sk = d.d_date_sk
JOIN item i ON s.cs_item_sk = i.i_item_sk
JOIN warehouse w ON s.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN returns r
    ON s.cs_order_number = r.cr_order_number
    AND s.cs_item_sk = r.cr_item_sk
LEFT JOIN inv_agg inv
    ON inv.inv_date_sk = d.d_date_sk
    AND inv.inv_item_sk = s.cs_item_sk
    AND inv.inv_warehouse_sk = s.cs_warehouse_sk
GROUP BY d.d_year, d.d_moy, i.i_category, w.w_warehouse_name
ORDER BY d.d_year, d.d_moy, i.i_category, w.w_warehouse_name
