WITH
  store_agg AS (
    SELECT
      sr.sr_customer_sk AS customer_sk,
      SUM(sr.sr_net_loss) AS store_net_loss,
      COUNT(DISTINCT r.r_reason_desc) AS store_reason_cnt
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY sr.sr_customer_sk
  ),
  catalog_agg AS (
    SELECT
      cr.cr_returning_customer_sk AS customer_sk,
      SUM(DISTINCT cr.cr_return_amount) AS catalog_net_loss,
      COUNT(DISTINCT r.r_reason_desc) AS catalog_reason_cnt
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY cr.cr_returning_customer_sk
  ),
  common_customers AS (
    SELECT customer_sk FROM store_agg
    INTERSECT
    SELECT customer_sk FROM catalog_agg
  ),
  store_only_customers AS (
    SELECT customer_sk FROM store_agg
    EXCEPT
    SELECT customer_sk FROM catalog_agg
  ),
  catalog_only_customers AS (
    SELECT customer_sk FROM catalog_agg
    EXCEPT
    SELECT customer_sk FROM store_agg
  ),
  common_data AS (
    SELECT
      s.customer_sk,
      s.store_net_loss,
      c.catalog_net_loss,
      s.store_reason_cnt,
      c.catalog_reason_cnt,
      'common' AS set_type
    FROM store_agg s
    JOIN catalog_agg c ON s.customer_sk = c.customer_sk
    WHERE s.customer_sk IN (SELECT customer_sk FROM common_customers)
  ),
  store_only_data AS (
    SELECT
      s.customer_sk,
      s.store_net_loss,
      NULL AS catalog_net_loss,
      s.store_reason_cnt,
      NULL AS catalog_reason_cnt,
      'store_only' AS set_type
    FROM store_agg s
    WHERE s.customer_sk IN (SELECT customer_sk FROM store_only_customers)
  ),
  catalog_only_data AS (
    SELECT
      c.customer_sk,
      NULL AS store_net_loss,
      c.catalog_net_loss,
      NULL AS store_reason_cnt,
      c.catalog_reason_cnt,
      'catalog_only' AS set_type
    FROM catalog_agg c
    WHERE c.customer_sk IN (SELECT customer_sk FROM catalog_only_customers)
  ),
  combined AS (
    SELECT * FROM common_data
    UNION ALL
    SELECT * FROM store_only_data
    UNION ALL
    SELECT * FROM catalog_only_data
  )
SELECT
  cd.customer_sk,
  cd.set_type,
  CASE
    WHEN cd.store_net_loss IS NOT NULL AND cd.catalog_net_loss IS NOT NULL THEN
      CASE WHEN cd.store_net_loss > cd.catalog_net_loss THEN 'Store Higher' ELSE 'Catalog Higher' END
    WHEN cd.store_net_loss IS NOT NULL THEN 'Store Only'
    WHEN cd.catalog_net_loss IS NOT NULL THEN 'Catalog Only'
    ELSE 'None'
  END AS loss_comparison,
  cd.store_net_loss,
  cd.catalog_net_loss,
  cd.store_reason_cnt,
  cd.catalog_reason_cnt
FROM combined cd
WHERE EXISTS (
  SELECT 1
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE ss.ss_customer_sk = cd.customer_sk
    AND d.d_year = 2001
)
ORDER BY cd.set_type, cd.store_net_loss DESC NULLS LAST
LIMIT 100
