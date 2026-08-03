WITH sampled_inventory AS (
    SELECT inv_date_sk,
           inv_item_sk,
           inv_warehouse_sk,
           inv_quantity_on_hand
    FROM inventory
    TABLESAMPLE BERNOULLI (10)
),
store_returns_electronics AS (
    SELECT
        s.s_store_id,
        d.d_year,
        SUM(sr.sr_return_amt) AS total_return_amount,
        COUNT(*) AS return_cnt,
        (
            SELECT SUM(sr2.sr_return_amt)
            FROM store_returns sr2
            WHERE sr2.sr_store_sk = s.s_store_sk
        ) AS store_total_return
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN sampled_inventory inv
        ON inv.inv_date_sk = d.d_date_sk
       AND inv.inv_item_sk = i.i_item_sk
    WHERE EXISTS (
            SELECT 1
            FROM promotion p
            WHERE p.p_item_sk = i.i_item_sk
              AND sr.sr_returned_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
          )
      AND d.d_year IN (2000, 2001)
      AND i.i_category = 'Electronics'
    GROUP BY s.s_store_id, d.d_year, s.s_store_sk
),
store_returns_furniture AS (
    SELECT
        s.s_store_id,
        d.d_year,
        SUM(sr.sr_return_amt) AS total_return_amount,
        COUNT(*) AS return_cnt,
        (
            SELECT SUM(sr2.sr_return_amt)
            FROM store_returns sr2
            WHERE sr2.sr_store_sk = s.s_store_sk
        ) AS store_total_return
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE NOT EXISTS (
            SELECT 1
            FROM promotion p
            WHERE p.p_item_sk = i.i_item_sk
              AND sr.sr_returned_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
          )
      AND d.d_year IN (2000, 2001)
      AND i.i_category = 'Furniture'
    GROUP BY s.s_store_id, d.d_year, s.s_store_sk
)
SELECT *
FROM store_returns_electronics
WHERE store_total_return > 0
UNION ALL
SELECT *
FROM store_returns_furniture
ORDER BY total_return_amount DESC
LIMIT 100
