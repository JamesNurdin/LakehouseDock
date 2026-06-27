WITH catalog_sales_month AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        cs.cs_warehouse_sk AS warehouse_sk,
        cs.cs_net_profit AS net_profit,
        cs.cs_net_paid AS net_paid,
        d.d_date
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-01-31'
),
web_sales_month AS (
    SELECT
        ws.ws_item_sk AS item_sk,
        ws.ws_warehouse_sk AS warehouse_sk,
        ws.ws_net_profit AS net_profit,
        ws.ws_net_paid AS net_paid,
        d.d_date
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-01-31'
),
sales_agg AS (
    SELECT
        item_sk,
        warehouse_sk,
        SUM(net_profit) AS total_net_profit,
        SUM(net_paid) AS total_net_paid
    FROM (
        SELECT item_sk, warehouse_sk, net_profit, net_paid FROM catalog_sales_month
        UNION ALL
        SELECT item_sk, warehouse_sk, net_profit, net_paid FROM web_sales_month
    ) s
    GROUP BY item_sk, warehouse_sk
),
returns_month AS (
    SELECT
        cr.cr_item_sk AS item_sk,
        cr.cr_warehouse_sk AS warehouse_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_return_loss,
        d.d_date
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-01-31'
    GROUP BY cr.cr_item_sk, cr.cr_warehouse_sk, d.d_date
),
returns_agg AS (
    SELECT
        item_sk,
        warehouse_sk,
        SUM(total_return_amount) AS total_return_amount,
        SUM(total_return_loss) AS total_return_loss
    FROM returns_month
    GROUP BY item_sk, warehouse_sk
),
inventory_month AS (
    SELECT
        inv.inv_item_sk AS item_sk,
        inv.inv_warehouse_sk AS warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand,
        d.d_date
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_date = (
        SELECT MAX(d2.d_date)
        FROM date_dim d2
        WHERE d2.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-01-31'
    )
    GROUP BY inv.inv_item_sk, inv.inv_warehouse_sk, d.d_date
),
item_warehouse_keys AS (
    SELECT item_sk, warehouse_sk FROM sales_agg
    UNION
    SELECT item_sk, warehouse_sk FROM returns_agg
    UNION
    SELECT item_sk, warehouse_sk FROM inventory_month
)
SELECT
    i.i_manufact AS manufacturer,
    w.w_warehouse_name AS warehouse,
    COALESCE(s.total_net_profit, 0) - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns,
    COALESCE(s.total_net_paid, 0) - COALESCE(r.total_return_amount, 0) AS net_paid_after_returns,
    COALESCE(iq.total_qty_on_hand, 0) AS quantity_on_hand
FROM item_warehouse_keys kw
LEFT JOIN sales_agg s
    ON kw.item_sk = s.item_sk AND kw.warehouse_sk = s.warehouse_sk
LEFT JOIN returns_agg r
    ON kw.item_sk = r.item_sk AND kw.warehouse_sk = r.warehouse_sk
LEFT JOIN inventory_month iq
    ON kw.item_sk = iq.item_sk AND kw.warehouse_sk = iq.warehouse_sk
JOIN item i ON kw.item_sk = i.i_item_sk
JOIN warehouse w ON kw.warehouse_sk = w.w_warehouse_sk
ORDER BY net_profit_after_returns DESC
LIMIT 100
