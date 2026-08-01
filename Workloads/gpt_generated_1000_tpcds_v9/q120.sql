WITH sales AS (
    SELECT
        'sale' AS txn_type,
        ws.ws_order_number AS txn_id,
        ws.ws_net_paid_inc_ship_tax AS amount,
        d.d_date AS txn_date,
        ws.ws_item_sk AS item_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ws.ws_net_paid_inc_ship_tax > (
          SELECT avg(ws2.ws_net_paid_inc_ship_tax)
          FROM web_sales ws2
          JOIN date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
          WHERE d2.d_year = 2001
      )
      AND EXISTS (
          SELECT 1
          FROM web_sales ws3
          WHERE ws3.ws_item_sk = ws.ws_item_sk
            AND ws3.ws_quantity > 5
            AND ws3.ws_sold_date_sk = ws.ws_sold_date_sk
      )
),
returns AS (
    SELECT
        'return' AS txn_type,
        sr.sr_ticket_number AS txn_id,
        -sr.sr_net_loss AS amount,
        d2.d_date AS txn_date,
        sr.sr_item_sk AS item_sk
    FROM store_returns sr
    JOIN date_dim d2 ON sr.sr_returned_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
      AND sr.sr_return_quantity > 10
),
unioned AS (
    SELECT txn_type, txn_id, amount, txn_date, item_sk FROM sales
    UNION ALL
    SELECT txn_type, txn_id, amount, txn_date, item_sk FROM returns
),
intersect_items AS (
    SELECT ws.ws_item_sk AS item_sk
    FROM web_sales ws
    JOIN date_dim d3 ON ws.ws_sold_date_sk = d3.d_date_sk
    WHERE d3.d_year = 2001
    INTERSECT
    SELECT sr.sr_item_sk AS item_sk
    FROM store_returns sr
    JOIN date_dim d4 ON sr.sr_returned_date_sk = d4.d_date_sk
    WHERE d4.d_year = 2001
)
SELECT
    u.txn_type,
    u.txn_id,
    u.amount,
    u.txn_date
FROM unioned u
WHERE NOT EXISTS (
    SELECT 1
    FROM intersect_items i
    WHERE i.item_sk = u.item_sk
)
ORDER BY u.amount DESC
LIMIT 100
