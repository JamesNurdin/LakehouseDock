WITH cc_filtered AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_state,
        cc.cc_manager,
        cc.cc_open_date_sk,
        cc.cc_closed_date_sk
    FROM call_center cc
    WHERE cc.cc_state = 'TN'
      AND cc.cc_class = 'large'
),
inv_agg AS (
    SELECT
        cc.cc_name,
        cc.cc_state,
        cc.cc_manager,
        d_inv.d_quarter_name,
        SUM(inv.inv_quantity_on_hand) AS total_qty,
        COUNT(DISTINCT inv.inv_item_sk) AS distinct_items,
        AVG(inv.inv_quantity_on_hand) AS avg_qty,
        d_open.d_date AS open_date,
        d_close.d_date AS close_date
    FROM inventory inv
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    JOIN cc_filtered cc ON d_inv.d_date_sk BETWEEN cc.cc_open_date_sk AND cc.cc_closed_date_sk
    JOIN date_dim d_open ON cc.cc_open_date_sk = d_open.d_date_sk
    JOIN date_dim d_close ON cc.cc_closed_date_sk = d_close.d_date_sk
    WHERE d_inv.d_year = 2022
    GROUP BY cc.cc_name, cc.cc_state, cc.cc_manager, d_inv.d_quarter_name, d_open.d_date, d_close.d_date
)
SELECT
    cc_name,
    cc_state,
    cc_manager,
    d_quarter_name,
    total_qty,
    distinct_items,
    avg_qty,
    DATE_DIFF('day', open_date, close_date) AS operational_days,
    RANK() OVER (PARTITION BY d_quarter_name ORDER BY total_qty DESC) AS quarterly_rank
FROM inv_agg
ORDER BY total_qty DESC
LIMIT 20
