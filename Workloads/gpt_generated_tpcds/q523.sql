WITH sales_agg AS (
    SELECT
        ds.d_year,
        ds.d_month_seq,
        w.w_warehouse_name,
        i.i_category,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN date_dim ds ON ws.ws_sold_date_sk = ds.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY ds.d_year, ds.d_month_seq, w.w_warehouse_name, i.i_category
),
returns_agg AS (
    SELECT
        dr.d_year,
        dr.d_month_seq,
        w.w_warehouse_name,
        i.i_category,
        SUM(cr.cr_return_amount) AS total_returns,
        SUM(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    GROUP BY dr.d_year, dr.d_month_seq, w.w_warehouse_name, i.i_category
),
inventory_agg AS (
    SELECT
        di.d_year,
        di.d_month_seq,
        w.w_warehouse_name,
        i.i_category,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty
    FROM inventory inv
    JOIN date_dim di ON inv.inv_date_sk = di.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY di.d_year, di.d_month_seq, w.w_warehouse_name, i.i_category
)
SELECT
    COALESCE(s.d_year, r.d_year, inv.d_year) AS year,
    COALESCE(s.d_month_seq, r.d_month_seq, inv.d_month_seq) AS month_seq,
    COALESCE(s.w_warehouse_name, r.w_warehouse_name, inv.w_warehouse_name) AS warehouse,
    COALESCE(s.i_category, r.i_category, inv.i_category) AS category,
    s.total_sales,
    s.total_profit,
    r.total_returns,
    r.total_return_loss,
    inv.avg_inventory_qty
FROM sales_agg s
FULL OUTER JOIN returns_agg r
    ON s.d_year = r.d_year
    AND s.d_month_seq = r.d_month_seq
    AND s.w_warehouse_name = r.w_warehouse_name
    AND s.i_category = r.i_category
FULL OUTER JOIN inventory_agg inv
    ON COALESCE(s.d_year, r.d_year) = inv.d_year
    AND COALESCE(s.d_month_seq, r.d_month_seq) = inv.d_month_seq
    AND COALESCE(s.w_warehouse_name, r.w_warehouse_name) = inv.w_warehouse_name
    AND COALESCE(s.i_category, r.i_category) = inv.i_category
ORDER BY year, month_seq, warehouse, category
