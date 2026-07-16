WITH catalog_returns_agg AS (
    SELECT
        d.d_date AS activity_date,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_date
),
web_sales_agg AS (
    SELECT
        d_sold.d_date AS activity_date,
        AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_shipping_delay,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid_inc_tax,
        SUM(ws.ws_ext_sales_price) AS total_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(*) AS sales_count
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    GROUP BY d_sold.d_date
),
inventory_agg AS (
    SELECT
        d.d_date AS activity_date,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
        COUNT(*) AS inventory_records
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    GROUP BY d.d_date
),
store_closure_agg AS (
    SELECT
        d.d_date AS activity_date,
        COUNT(*) AS stores_closed,
        COUNT(DISTINCT s.s_store_id) AS distinct_store_ids_closed
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    GROUP BY d.d_date
)
SELECT
    COALESCE(cr.activity_date, ws.activity_date, inv.activity_date, sc.activity_date) AS activity_date,
    cr.total_return_amount,
    cr.total_net_loss,
    cr.return_count,
    ws.total_net_profit,
    ws.total_net_paid_inc_tax,
    ws.total_sales_price,
    ws.order_count,
    ws.sales_count,
    ws.avg_shipping_delay,
    inv.total_inventory_qty,
    inv.inventory_records,
    sc.stores_closed,
    sc.distinct_store_ids_closed,
    CASE
        WHEN ws.total_net_profit IS NOT NULL AND ws.total_net_profit <> 0 THEN cr.total_return_amount / ws.total_net_profit
        ELSE NULL
    END AS return_to_profit_ratio,
    CASE
        WHEN ws.order_count IS NOT NULL AND ws.order_count <> 0 THEN inv.total_inventory_qty / ws.order_count
        ELSE NULL
    END AS avg_inventory_per_order
FROM catalog_returns_agg cr
FULL OUTER JOIN web_sales_agg ws ON cr.activity_date = ws.activity_date
FULL OUTER JOIN inventory_agg inv ON COALESCE(cr.activity_date, ws.activity_date) = inv.activity_date
FULL OUTER JOIN store_closure_agg sc ON COALESCE(cr.activity_date, ws.activity_date, inv.activity_date) = sc.activity_date
WHERE COALESCE(cr.activity_date, ws.activity_date, inv.activity_date, sc.activity_date) BETWEEN DATE '2020-01-01' AND DATE '2023-12-31'
ORDER BY activity_date
