/*
  Analytical query: monthly net sales, profit and returns by item category for the year 2001,
  together with the on‑hand inventory at month end.
  Joins follow the TPC‑DS join rules and all columns are drawn from the listed tables.
*/
WITH cs AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        year(d.d_date)   AS year,
        month(d.d_date)  AS month,
        i.i_category,
        i.i_class,
        i.i_brand,
        sm.sm_ship_mode_id,
        w.w_warehouse_name
    FROM catalog_sales cs
    JOIN date_dim d      ON cs.cs_sold_date_sk   = d.d_date_sk
    JOIN item i          ON cs.cs_item_sk       = i.i_item_sk
    JOIN ship_mode sm    ON cs.cs_ship_mode_sk  = sm.sm_ship_mode_sk
    JOIN warehouse w     ON cs.cs_warehouse_sk  = w.w_warehouse_sk
    WHERE year(d.d_date) = 2001
),
cr AS (
    SELECT
        cr.cr_order_number,
        cr.cr_item_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        year(d_ret.d_date)   AS return_year,
        month(d_ret.d_date)  AS return_month,
        i_ret.i_category      AS return_category
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN item i_ret    ON cr.cr_item_sk          = i_ret.i_item_sk
    WHERE year(d_ret.d_date) = 2001
),
inv AS (
    SELECT
        i.i_category,
        year(d_inv.d_date)   AS inv_year,
        month(d_inv.d_date)  AS inv_month,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory inv
    JOIN date_dim d_inv ON inv.inv_date_sk   = d_inv.d_date_sk
    JOIN item i        ON inv.inv_item_sk  = i.i_item_sk
    WHERE year(d_inv.d_date) = 2001
    GROUP BY i.i_category, year(d_inv.d_date), month(d_inv.d_date)
)
SELECT
    cs.year,
    cs.month,
    cs.i_category,
    SUM(cs.cs_quantity)               AS total_quantity_sold,
    SUM(cs.cs_net_paid)               AS total_sales_amount,
    SUM(cs.cs_net_profit)             AS total_net_profit,
    COALESCE(SUM(cr.cr_return_quantity), 0) AS total_quantity_returned,
    COALESCE(SUM(cr.cr_return_amount),   0) AS total_return_amount,
    COALESCE(SUM(cr.cr_net_loss),        0) AS total_return_loss,
    COALESCE(inv.total_quantity_on_hand, 0)   AS inventory_on_hand
FROM cs
LEFT JOIN cr  ON cs.cs_order_number = cr.cr_order_number
               AND cs.cs_item_sk      = cr.cr_item_sk
LEFT JOIN inv ON cs.i_category = inv.i_category
               AND cs.year       = inv.inv_year
               AND cs.month      = inv.inv_month
GROUP BY cs.year, cs.month, cs.i_category, inv.total_quantity_on_hand
ORDER BY cs.year, cs.month, cs.i_category
