WITH inventory_summary AS (
    SELECT
        i.i_item_sk,
        w.w_warehouse_name,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY i.i_item_sk, w.w_warehouse_name
)

SELECT
    sr.sr_ticket_number AS return_ticket,
    i.i_item_id AS item_id,
    inv_sum.w_warehouse_name AS warehouse_name,
    inv_sum.total_on_hand,
    sr.sr_return_quantity AS return_quantity,
    sr.sr_return_amt_inc_tax AS return_amount_inc_tax,
    td.t_shift,
    p.p_promo_name AS promo_name,
    CASE WHEN sr.sr_return_amt_inc_tax > 500 THEN 'High' ELSE 'Low' END AS return_category
FROM store_returns sr
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
JOIN inventory_summary inv_sum ON inv_sum.i_item_sk = i.i_item_sk
WHERE sr.sr_return_quantity > 30
  AND td.t_shift = 'first               '

UNION ALL

SELECT
    sr.sr_ticket_number AS return_ticket,
    i.i_item_id AS item_id,
    inv_sum.w_warehouse_name AS warehouse_name,
    inv_sum.total_on_hand,
    sr.sr_return_quantity AS return_quantity,
    sr.sr_return_amt_inc_tax AS return_amount_inc_tax,
    td.t_shift,
    p.p_promo_name AS promo_name,
    CASE WHEN sr.sr_return_amt_inc_tax > 500 THEN 'High' ELSE 'Low' END AS return_category
FROM store_returns sr
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
JOIN inventory_summary inv_sum ON inv_sum.i_item_sk = i.i_item_sk
WHERE sr.sr_return_quantity <= 30
  AND td.t_shift = 'second              '

ORDER BY return_category DESC, return_amount_inc_tax DESC
LIMIT 100
