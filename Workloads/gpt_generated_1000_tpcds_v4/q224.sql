WITH inv_agg AS (
    SELECT
        inv.inv_warehouse_sk,
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory inv
    GROUP BY inv.inv_warehouse_sk, inv.inv_item_sk
)
SELECT
    w.w_warehouse_name,
    i.i_product_name,
    sr.sr_return_amt,
    inv_agg.total_qty_on_hand,
    p.p_discount_active,
    td.t_hour,
    ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_id ORDER BY sr.sr_return_amt DESC) AS rn_warehouse,
    AVG(sr.sr_return_amt) OVER (PARTITION BY i.i_item_sk) AS avg_return_amt_item,
    CASE
        WHEN sr.sr_return_amt > (
            SELECT AVG(sr2.sr_return_amt)
            FROM store_returns sr2
            WHERE sr2.sr_item_sk = i.i_item_sk
        ) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS return_vs_avg
FROM store_returns sr
JOIN time_dim td
    ON sr.sr_return_time_sk = td.t_time_sk
JOIN item i
    ON sr.sr_item_sk = i.i_item_sk
JOIN promotion p
    ON p.p_item_sk = i.i_item_sk
JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
JOIN warehouse w
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN inv_agg
    ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
   AND inv_agg.inv_item_sk = i.i_item_sk
WHERE
    td.t_hour BETWEEN 8 AND 20
    AND td.t_am_pm = 'PM'
    AND i.i_current_price > 20
    AND p.p_cost < 500
    AND w.w_warehouse_sq_ft > 600000
    AND inv.inv_quantity_on_hand > 0
    AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
          AND p2.p_discount_active = 'Y'
    )
ORDER BY w.w_warehouse_name, rn_warehouse
LIMIT 100
