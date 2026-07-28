WITH joined AS (
    SELECT
        d.d_date,
        d.d_year,
        d.d_quarter_seq,
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_city,
        w.w_state,
        i.inv_item_sk,
        i.inv_quantity_on_hand
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND d.d_quarter_seq = 12
      AND d.d_holiday = 'N'
      AND w.w_country = 'United States'
      AND w.w_state = 'CA'
      AND i.inv_quantity_on_hand > 0
      AND i.inv_item_sk BETWEEN 101410 AND 101425
)
SELECT
    w_warehouse_name,
    w_city,
    w_state,
    d_year,
    d_quarter_seq,
    SUM(inv_quantity_on_hand) AS total_qty,
    RANK() OVER (PARTITION BY d_year, d_quarter_seq ORDER BY SUM(inv_quantity_on_hand) DESC) AS warehouse_rank,
    SUM(SUM(inv_quantity_on_hand)) OVER (
        PARTITION BY d_year
        ORDER BY d_quarter_seq
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cum_qty_year_to_quarter
FROM joined
GROUP BY
    w_warehouse_name,
    w_city,
    w_state,
    d_year,
    d_quarter_seq
ORDER BY total_qty DESC
LIMIT 100
