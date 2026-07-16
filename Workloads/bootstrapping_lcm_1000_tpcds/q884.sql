WITH inv_by_warehouse_date AS (
    SELECT
        inv_warehouse_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk, inv_date_sk
),
returns_by_warehouse_date AS (
    SELECT
        cr_warehouse_sk,
        cr_returned_date_sk,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(*) AS num_returns,
        SUM(cr_return_quantity) AS total_return_qty
    FROM catalog_returns
    GROUP BY cr_warehouse_sk, cr_returned_date_sk
)
SELECT
    d.d_year,
    d.d_quarter_name,
    w.w_state,
    w.w_city,
    s.s_state,
    r.total_net_loss,
    r.num_returns,
    r.total_return_qty,
    i.total_quantity_on_hand,
    r.total_net_loss / NULLIF(i.total_quantity_on_hand, 0) AS loss_per_inventory,
    ROW_NUMBER() OVER (PARTITION BY d.d_year, w.w_state ORDER BY r.total_net_loss DESC) AS rank_by_loss
FROM returns_by_warehouse_date r
JOIN date_dim d
    ON r.cr_returned_date_sk = d.d_date_sk
JOIN warehouse w
    ON r.cr_warehouse_sk = w.w_warehouse_sk
JOIN inv_by_warehouse_date i
    ON i.inv_warehouse_sk = w.w_warehouse_sk
    AND i.inv_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
  AND i.total_quantity_on_hand > 0
ORDER BY d.d_year, w.w_state, rank_by_loss
LIMIT 100
