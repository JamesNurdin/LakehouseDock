WITH
  store_return_summary AS (
    SELECT
      s.s_store_id AS entity_id,
      d.d_date AS return_date,
      SUM(sr.sr_return_quantity) AS total_qty,
      SUM(sr.sr_net_loss) AS total_loss,
      CASE WHEN SUM(sr.sr_net_loss) > 0 THEN 'Loss' ELSE 'Profit' END AS net_status
    FROM store s
    FULL OUTER JOIN store_returns sr
      ON s.s_store_sk = sr.sr_store_sk
    LEFT JOIN date_dim d
      ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE sr.sr_return_quantity IS NOT NULL
    GROUP BY s.s_store_id, d.d_date
  ),
  store_return_keys AS (
    SELECT sr.sr_ticket_number AS order_key
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 0
  ),
  catalog_return_keys AS (
    SELECT cr.cr_order_number AS order_key
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 0
  ),
  unmatched_store_keys AS (
    SELECT order_key
    FROM store_return_keys
    EXCEPT
    SELECT order_key
    FROM catalog_return_keys
  ),
  customers_without_store_returns AS (
    SELECT
      ca.ca_address_id AS entity_id,
      NULL AS return_date,
      0 AS total_qty,
      0 AS total_loss,
      CASE WHEN ca.ca_gmt_offset >= 0 THEN 'East' ELSE 'West' END AS net_status
    FROM customer_address ca
    WHERE NOT EXISTS (
      SELECT 1
      FROM store_returns sr
      WHERE sr.sr_addr_sk = ca.ca_address_sk
    )
  ),
  unmatched_orders AS (
    SELECT
      CAST(order_key AS VARCHAR) AS entity_id,
      NULL AS return_date,
      NULL AS total_qty,
      NULL AS total_loss,
      'UnmatchedOrder' AS net_status
    FROM unmatched_store_keys
  )
SELECT entity_id,
       return_date,
       total_qty,
       total_loss,
       net_status
FROM store_return_summary
WHERE NOT EXISTS (
  SELECT 1
  FROM catalog_returns cr
  WHERE cr.cr_order_number = CAST(store_return_summary.entity_id AS INTEGER)
)
UNION ALL
SELECT entity_id,
       return_date,
       total_qty,
       total_loss,
       net_status
FROM customers_without_store_returns
UNION ALL
SELECT entity_id,
       return_date,
       total_qty,
       total_loss,
       net_status
FROM unmatched_orders
ORDER BY entity_id
LIMIT 100
