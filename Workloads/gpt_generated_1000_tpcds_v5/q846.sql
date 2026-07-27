WITH returns_2000 AS (
    SELECT
        i.i_item_id AS item_id,
        w.w_warehouse_name AS warehouse_name,
        SUM(sr.sr_return_amt) AS total_return_amt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
                       AND inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2000
      AND w.w_county = 'Richland County'
      AND sr.sr_reversed_charge > 10
    GROUP BY i.i_item_id, w.w_warehouse_name
),
returns_2001 AS (
    SELECT
        i.i_item_id AS item_id,
        'ALL' AS warehouse_name,
        SUM(sr.sr_return_amt) AS total_return_amt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
                       AND inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND w.w_county = 'Fairfield County'
      AND sr.sr_return_quantity >= 1
    GROUP BY i.i_item_id
)
SELECT *
FROM returns_2000
UNION ALL
SELECT *
FROM returns_2001
ORDER BY total_return_amt DESC
LIMIT 100
