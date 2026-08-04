WITH combined AS (
    -- Web sales aggregated by warehouse state, item category and hour of day
    SELECT
        w.w_state AS state,
        i.i_category AS category,
        t.t_hour AS hour,
        SUM(ws.ws_ext_sales_price) AS sales_amount,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE EXISTS (
        SELECT 1
        FROM inventory inv
        WHERE inv.inv_item_sk = i.i_item_sk
          AND inv.inv_quantity_on_hand > 0
    )
    GROUP BY CUBE (w.w_state, i.i_category, t.t_hour)

    UNION ALL

    -- Store returns (as negative sales) aggregated by the same dimensions
    SELECT
        w.w_state AS state,
        i.i_category AS category,
        t.t_hour AS hour,
        -SUM(sr.sr_return_amt) AS sales_amount,
        COUNT(*) AS sales_cnt
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE inv.inv_quantity_on_hand > 0
    GROUP BY CUBE (w.w_state, i.i_category, t.t_hour)
)
SELECT
    state,
    category,
    hour,
    sales_amount,
    sales_cnt,
    rank
FROM (
    SELECT
        state,
        category,
        hour,
        sales_amount,
        sales_cnt,
        ROW_NUMBER() OVER (PARTITION BY state ORDER BY sales_amount DESC) AS rank
    FROM combined
) AS ranked
WHERE rank <= 5
ORDER BY state, rank
OFFSET 0
LIMIT 100
