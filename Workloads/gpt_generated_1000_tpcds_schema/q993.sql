WITH
    cc_small AS (
        SELECT cc_call_center_sk,
               cc_call_center_id,
               cc_name
        FROM call_center
        WHERE cc_state = 'CA'
        LIMIT 5
    ),
    ret_items AS (
        SELECT DISTINCT sr.sr_item_sk,
                        sr.sr_returned_date_sk
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        WHERE d.d_year IN (2000, 2001)
          AND EXISTS (
              SELECT 1
              FROM promotion p
              WHERE p.p_item_sk = sr.sr_item_sk
                AND p.p_start_date_sk <= sr.sr_returned_date_sk
                AND p.p_end_date_sk >= sr.sr_returned_date_sk
                AND p.p_channel_dmail = 'Y'
          )
    ),
    inv_items AS (
        SELECT DISTINCT inv.inv_item_sk,
                        inv.inv_date_sk
        FROM inventory inv
        JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
        JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
        WHERE d.d_year IN (2000, 2001)
          AND w.w_city IN ('Riverside', 'Salem')
    )
SELECT
    cc.cc_call_center_id,
    i.item_sk,
    d.d_date AS return_date,
    (
        SELECT SUM(sr2.sr_return_amt)
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = i.item_sk
          AND sr2.sr_returned_date_sk = i.date_sk
    ) AS total_return_amount
FROM (
        SELECT sr_item_sk AS item_sk,
               sr_returned_date_sk AS date_sk
        FROM ret_items
        INTERSECT
        SELECT inv_item_sk,
               inv_date_sk
        FROM inv_items
     ) AS i
CROSS JOIN cc_small cc
JOIN date_dim d ON i.date_sk = d.d_date_sk
ORDER BY total_return_amount DESC
LIMIT 100
