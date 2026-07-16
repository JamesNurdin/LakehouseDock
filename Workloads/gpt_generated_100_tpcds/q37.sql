WITH monthly_inventory AS (
    SELECT
        i.i_category,
        w.w_state,
        d.d_year,
        d.d_month_seq,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM inventory inv
    JOIN date_dim d
        ON inv.inv_date_sk = d.d_date_sk
    JOIN item i
        ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
    GROUP BY i.i_category, w.w_state, d.d_year, d.d_month_seq
),
monthly_change AS (
    SELECT
        i_category,
        w_state,
        d_year,
        d_month_seq,
        total_quantity,
        LAG(total_quantity) OVER (PARTITION BY i_category, w_state ORDER BY d_year, d_month_seq) AS prev_month_quantity
    FROM monthly_inventory
)
SELECT
    i_category,
    w_state,
    d_year,
    d_month_seq,
    total_quantity,
    prev_month_quantity,
    CASE
        WHEN prev_month_quantity IS NULL OR prev_month_quantity = 0 THEN NULL
        ELSE (total_quantity - prev_month_quantity) * 100.0 / prev_month_quantity
    END AS month_over_month_pct_change
FROM monthly_change
ORDER BY i_category, w_state, d_year, d_month_seq
