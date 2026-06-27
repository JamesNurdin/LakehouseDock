WITH monthly_warehouse_category AS (
    SELECT
        w.w_warehouse_name,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(inv.inv_quantity_on_hand) AS total_qty,
        COUNT(DISTINCT inv.inv_item_sk) AS distinct_items,
        AVG(i.i_current_price) AS avg_price
    FROM inventory inv
    JOIN date_dim d
        ON inv.inv_date_sk = d.d_date_sk
    JOIN item i
        ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_date >= DATE '2022-01-01'
      AND d.d_date < DATE '2023-01-01'
    GROUP BY
        w.w_warehouse_name,
        d.d_year,
        d.d_month_seq,
        i.i_category
)
SELECT
    w_warehouse_name,
    d_year,
    d_month_seq,
    i_category,
    total_qty,
    distinct_items,
    avg_price,
    RANK() OVER (
        PARTITION BY w_warehouse_name, d_year, d_month_seq
        ORDER BY total_qty DESC
    ) AS category_rank
FROM monthly_warehouse_category
ORDER BY
    w_warehouse_name,
    d_year,
    d_month_seq,
    category_rank
