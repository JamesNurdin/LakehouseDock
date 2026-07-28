WITH
  catalog_state AS (
    SELECT
      ca.ca_state AS state,
      SUM(cr.cr_return_amount) AS total_return_amount,
      COUNT(*) AS return_count
    FROM tpcds.catalog_returns cr
    JOIN tpcds.catalog_sales cs
      ON cr.cr_order_number = cs.cs_order_number
    JOIN tpcds.customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE EXISTS (
      SELECT 1
      FROM tpcds.promotion p
      WHERE p.p_promo_sk = cs.cs_promo_sk
        AND p.p_discount_active = 'Y'
    )
    GROUP BY ca.ca_state
  ),
  store_state AS (
    SELECT
      ca.ca_state AS state,
      SUM(sr.sr_return_amt) AS total_return_amount,
      COUNT(*) AS return_count
    FROM tpcds.store_returns sr
    JOIN tpcds.customer_address ca
      ON sr.sr_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state
  ),
  combined AS (
    SELECT state, total_return_amount, return_count, 'Catalog' AS source
    FROM catalog_state
    UNION ALL
    SELECT state, total_return_amount, return_count, 'Store' AS source
    FROM store_state
  )
SELECT
  c.state,
  c.source,
  c.total_return_amount,
  c.return_count,
  (
    SELECT AVG(total_return_amount)
    FROM combined
  ) AS avg_return_amount_across_sources
FROM combined c
ORDER BY c.state, c.source
