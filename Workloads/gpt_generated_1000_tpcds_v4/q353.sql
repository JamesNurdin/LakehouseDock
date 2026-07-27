WITH store_loss AS (
  SELECT
    'Store' AS location_type,
    s.s_store_id AS location_id,
    s.s_store_name AS location_name,
    SUM(sr.sr_net_loss) AS total_net_loss,
    d.d_year AS year
  FROM store_returns sr
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2002
  GROUP BY s.s_store_id, s.s_store_name, d.d_year
),
warehouse_loss AS (
  SELECT
    'Warehouse' AS location_type,
    w.w_warehouse_id AS location_id,
    w.w_warehouse_name AS location_name,
    SUM(cr.cr_net_loss) AS total_net_loss,
    d.d_year AS year
  FROM catalog_returns cr
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2002
    AND EXISTS (
      SELECT 1
      FROM promotion p
      WHERE p.p_item_sk = cr.cr_item_sk
        AND p.p_discount_active = 'Y'
    )
  GROUP BY w.w_warehouse_id, w.w_warehouse_name, d.d_year
),
combined AS (
  SELECT * FROM store_loss
  UNION ALL
  SELECT * FROM warehouse_loss
)
SELECT DISTINCT
  location_type,
  location_id,
  location_name,
  total_net_loss,
  year,
  (SELECT AVG(sr2.sr_net_loss)
   FROM store_returns sr2
   JOIN date_dim d2 ON sr2.sr_returned_date_sk = d2.d_date_sk
   WHERE d2.d_year = 2002) AS avg_store_net_loss_2002
FROM combined
ORDER BY total_net_loss DESC
LIMIT 100
