WITH returns_furniture AS (
    SELECT
        sr.sr_ticket_number,
        i.i_item_id,
        i.i_class,
        r.r_reason_desc,
        sr.sr_return_amt,
        (
            SELECT AVG(sr2.sr_return_amt)
            FROM store_returns sr2
            WHERE sr2.sr_reason_sk = sr.sr_reason_sk
        ) AS avg_return_amt_for_reason,
        inv.inv_quantity_on_hand,
        w.w_zip,
        ROW_NUMBER() OVER (PARTITION BY r.r_reason_desc ORDER BY sr.sr_return_amt DESC) AS rn
    FROM store_returns sr
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.i_class = 'furniture'
      AND cd.cd_gender = 'F'
      AND inv.inv_quantity_on_hand > 500
      AND w.w_zip = '44593'
),
returns_shirts AS (
    SELECT
        sr.sr_ticket_number,
        i.i_item_id,
        i.i_class,
        r.r_reason_desc,
        sr.sr_return_amt,
        (
            SELECT AVG(sr2.sr_return_amt)
            FROM store_returns sr2
            WHERE sr2.sr_reason_sk = sr.sr_reason_sk
        ) AS avg_return_amt_for_reason,
        inv.inv_quantity_on_hand,
        w.w_zip,
        ROW_NUMBER() OVER (PARTITION BY r.r_reason_desc ORDER BY sr.sr_return_amt DESC) AS rn
    FROM store_returns sr
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.i_class = 'shirts'
      AND cd.cd_gender = 'M'
      AND inv.inv_quantity_on_hand > 500
      AND w.w_zip = '44593'
)
SELECT
    sr_ticket_number,
    i_item_id,
    i_class,
    r_reason_desc,
    sr_return_amt,
    avg_return_amt_for_reason,
    inv_quantity_on_hand,
    w_zip,
    rn
FROM returns_furniture
UNION ALL
SELECT
    sr_ticket_number,
    i_item_id,
    i_class,
    r_reason_desc,
    sr_return_amt,
    avg_return_amt_for_reason,
    inv_quantity_on_hand,
    w_zip,
    rn
FROM returns_shirts
LIMIT 100
