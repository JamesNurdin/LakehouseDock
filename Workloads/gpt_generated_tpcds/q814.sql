WITH sales_agg AS (
    SELECT
        cs.cs_warehouse_sk AS warehouse_sk,
        date_trunc('month', d_sales.d_date) AS month,
        sum(cs.cs_net_profit) AS total_sales_profit
    FROM catalog_sales cs
    JOIN date_dim d_sales
        ON cs.cs_sold_date_sk = d_sales.d_date_sk
    WHERE d_sales.d_date >= DATE '2020-01-01'
      AND d_sales.d_date < DATE '2021-01-01'
    GROUP BY cs.cs_warehouse_sk, date_trunc('month', d_sales.d_date)
),
returns_agg AS (
    SELECT
        cr.cr_warehouse_sk AS warehouse_sk,
        date_trunc('month', d_return.d_date) AS month,
        sum(cr.cr_net_loss) AS total_returns_loss
    FROM catalog_returns cr
    JOIN date_dim d_return
        ON cr.cr_returned_date_sk = d_return.d_date_sk
    WHERE d_return.d_date >= DATE '2020-01-01'
      AND d_return.d_date < DATE '2021-01-01'
    GROUP BY cr.cr_warehouse_sk, date_trunc('month', d_return.d_date)
),
inventory_agg AS (
    SELECT
        inv.inv_warehouse_sk AS warehouse_sk,
        date_trunc('month', d_inv.d_date) AS month,
        avg(inv.inv_quantity_on_hand) AS avg_quantity_on_hand
    FROM inventory inv
    JOIN date_dim d_inv
        ON inv.inv_date_sk = d_inv.d_date_sk
    WHERE d_inv.d_date >= DATE '2020-01-01'
      AND d_inv.d_date < DATE '2021-01-01'
    GROUP BY inv.inv_warehouse_sk, date_trunc('month', d_inv.d_date)
)
SELECT
    w.w_warehouse_name,
    sales.month,
    coalesce(sales.total_sales_profit, 0) - coalesce(returns.total_returns_loss, 0) AS net_profit,
    coalesce(inventory.avg_quantity_on_hand, 0) AS avg_inventory_on_hand
FROM sales_agg sales
LEFT JOIN returns_agg returns
    ON sales.warehouse_sk = returns.warehouse_sk
    AND sales.month = returns.month
LEFT JOIN inventory_agg inventory
    ON sales.warehouse_sk = inventory.warehouse_sk
    AND sales.month = inventory.month
JOIN warehouse w
    ON sales.warehouse_sk = w.w_warehouse_sk
ORDER BY w.w_warehouse_name, sales.month
