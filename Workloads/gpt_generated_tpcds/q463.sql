WITH returns_monthly AS (
    SELECT
        date_trunc('month', d.d_date) AS month,
        i.i_category,
        sum(wr.wr_return_quantity) AS total_return_quantity,
        sum(wr.wr_return_amt) AS total_return_amount,
        sum(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
    GROUP BY date_trunc('month', d.d_date), i.i_category
),
inventory_monthly AS (
    SELECT
        date_trunc('month', d.d_date) AS month,
        i.i_category,
        sum(inv.inv_quantity_on_hand) AS total_quantity_on_hand,
        sum(inv.inv_quantity_on_hand * i.i_current_price) AS total_inventory_value
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
    GROUP BY date_trunc('month', d.d_date), i.i_category
)
SELECT
    r.month,
    r.i_category,
    r.total_return_quantity,
    r.total_return_amount,
    r.total_net_loss,
    i.total_quantity_on_hand,
    i.total_inventory_value,
    (r.total_return_quantity / nullif(i.total_quantity_on_hand, 0)) AS return_quantity_per_inventory,
    (r.total_net_loss / nullif(r.total_return_quantity, 0)) AS net_loss_per_returned_item
FROM returns_monthly r
LEFT JOIN inventory_monthly i
    ON r.month = i.month
   AND r.i_category = i.i_category
ORDER BY r.month, r.i_category
