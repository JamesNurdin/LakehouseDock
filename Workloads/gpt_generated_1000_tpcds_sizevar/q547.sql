WITH
  returns_by_state AS (
    SELECT
      ca.ca_state AS state,
      'return' AS metric,
      CASE WHEN i.i_current_price > 100 THEN 'high' ELSE 'low' END AS category,
      SUM(sr.sr_return_amt) AS amount
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    LEFT JOIN LATERAL (
      SELECT SUM(sr2.sr_return_quantity) AS total_qty
      FROM store_returns sr2
      WHERE sr2.sr_item_sk = i.i_item_sk
    ) l ON true
    WHERE d.d_year = 2001
    GROUP BY ca.ca_state,
             CASE WHEN i.i_current_price > 100 THEN 'high' ELSE 'low' END
  ),
  inventory_by_state AS (
    SELECT
      w.w_state AS state,
      'inventory' AS metric,
      CASE WHEN inv.inv_quantity_on_hand > 500 THEN 'high' ELSE 'low' END AS category,
      CAST(SUM(inv.inv_quantity_on_hand) AS DECIMAL(12,2)) AS amount
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND inv.inv_warehouse_sk IN (
        SELECT w2.w_warehouse_sk
        FROM inventory inv2
        JOIN warehouse w2 ON inv2.inv_warehouse_sk = w2.w_warehouse_sk
        WHERE inv2.inv_quantity_on_hand > 500
      )
    GROUP BY w.w_state,
             CASE WHEN inv.inv_quantity_on_hand > 500 THEN 'high' ELSE 'low' END
  )
SELECT state,
       metric,
       category,
       amount
FROM returns_by_state
UNION
SELECT state,
       metric,
       category,
       amount
FROM inventory_by_state
ORDER BY state,
         metric,
         category,
         amount DESC
LIMIT 100
