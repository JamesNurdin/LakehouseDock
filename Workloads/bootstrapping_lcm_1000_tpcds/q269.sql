WITH inv_agg AS (
    SELECT 
        inv_item_sk,
        AVG(inv_quantity_on_hand) AS avg_qty_on_hand
    FROM inventory inv
    JOIN date_dim d_inv
        ON inv.inv_date_sk = d_inv.d_date_sk
    WHERE d_inv.d_year = 2022
    GROUP BY inv_item_sk
),
aggregated_returns AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_city,
        s.s_store_id,
        s.s_city,
        dr_ret.d_year,
        dr_ret.d_month_seq,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
        AVG(cr.cr_return_tax) AS avg_return_tax,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        COALESCE(inv_agg.avg_qty_on_hand, 0) AS avg_inventory_qty_on_hand,
        MAX(s.s_floor_space) AS max_store_floor_space,
        MIN(dr_cc_open.d_date) AS call_center_open_date,
        MAX(dr_cc_closed.d_date) AS call_center_closed_date
    FROM catalog_returns cr
    JOIN date_dim dr_ret
        ON cr.cr_returned_date_sk = dr_ret.d_date_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN date_dim dr_cc_open
        ON cc.cc_open_date_sk = dr_cc_open.d_date_sk
    LEFT JOIN date_dim dr_cc_closed
        ON cc.cc_closed_date_sk = dr_cc_closed.d_date_sk
    JOIN inventory inv
        ON inv.inv_item_sk = cr.cr_item_sk
        AND inv.inv_date_sk = dr_ret.d_date_sk
    LEFT JOIN inv_agg
        ON inv.inv_item_sk = inv_agg.inv_item_sk
    JOIN store s
        ON s.s_closed_date_sk = dr_ret.d_date_sk
    WHERE dr_ret.d_year BETWEEN 2020 AND 2022
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_city,
        s.s_store_id,
        s.s_city,
        dr_ret.d_year,
        dr_ret.d_month_seq,
        inv_agg.avg_qty_on_hand
)
SELECT
    cc_call_center_id,
    cc_name,
    cc_city,
    s_store_id,
    s_city,
    d_year,
    d_month_seq,
    total_return_amount,
    total_net_loss,
    distinct_orders,
    avg_return_tax,
    total_return_quantity,
    avg_inventory_qty_on_hand,
    max_store_floor_space,
    call_center_open_date,
    call_center_closed_date,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_return_amount DESC) AS rank_by_year
FROM aggregated_returns
WHERE total_return_amount > 0
ORDER BY d_year, d_month_seq, total_return_amount DESC
LIMIT 100
