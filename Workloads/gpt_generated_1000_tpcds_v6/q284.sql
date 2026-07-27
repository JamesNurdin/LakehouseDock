WITH raw AS (
    SELECT
        i.i_category,
        s.s_city AS store_city,
        cc.cc_name AS call_center_name,
        d.d_year,
        inv.inv_quantity_on_hand
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN store s2 ON s2.s_closed_date_sk = d.d_date_sk
    JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
    JOIN call_center cc2 ON cc2.cc_closed_date_sk = d.d_date_sk
    JOIN date_dim d2 ON cc2.cc_closed_date_sk = d2.d_date_sk
    JOIN date_dim d3 ON s2.s_closed_date_sk = d3.d_date_sk
    JOIN inventory inv2 ON inv2.inv_date_sk = d.d_date_sk
    JOIN item i2 ON inv2.inv_item_sk = i2.i_item_sk
    WHERE inv.inv_quantity_on_hand > 0
      AND inv2.inv_quantity_on_hand > 0
      AND d.d_year = 2001
),
agg AS (
    SELECT
        i_category,
        store_city,
        call_center_name,
        d_year,
        SUM(inv_quantity_on_hand) AS total_qty
    FROM raw
    GROUP BY i_category, store_city, call_center_name, d_year
)
SELECT
    i_category,
    store_city,
    call_center_name,
    d_year,
    total_qty,
    SUM(total_qty) OVER (PARTITION BY i_category ORDER BY d_year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_qty,
    RANK() OVER (PARTITION BY i_category ORDER BY total_qty DESC) AS qty_rank
FROM agg
ORDER BY total_qty DESC
LIMIT 100
