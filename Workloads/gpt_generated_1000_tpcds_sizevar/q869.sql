WITH
  -- 10% random sample of catalog returns (required for TABLESAMPLE)
  sampled_cr AS (
    SELECT *
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10)
  ),

  -- Aggregate the sampled catalog returns per catalog page (pre‑aggregation CTE)
  catalog_return_agg AS (
    SELECT
      cr_catalog_page_sk,
      SUM(cr_return_amount)               AS total_return_amount,
      COUNT(*)                            AS return_cnt,
      MIN(cr_returning_customer_sk)       AS returning_customer_sk,
      MAX(cr_returned_date_sk)            AS returned_date_sk,
      MAX(cr_ship_mode_sk)                AS ship_mode_sk,
      MAX(cr_returning_addr_sk)           AS returning_addr_sk,
      MAX(cr_returning_cdemo_sk)          AS returning_cdemo_sk
    FROM sampled_cr
    GROUP BY cr_catalog_page_sk
  ),

  -- Customers that have a catalog return but no web return (EXCEPT example)
  catalog_only_customers AS (
    SELECT cr_returning_customer_sk
    FROM sampled_cr
    EXCEPT
    SELECT wr_returning_customer_sk
    FROM web_returns
  )

SELECT
  d_ret.d_year                                          AS return_year,
  cp.cp_department                                      AS department,
  sm.sm_type                                            AS ship_type,
  s.s_store_name                                        AS store_name,
  CASE
    WHEN cra.total_return_amount > 10000 THEN 'HIGH'
    ELSE 'LOW'
  END                                                   AS return_category,
  (
    SELECT SUM(wr2.wr_return_amt)
    FROM web_returns wr2
    WHERE wr2.wr_returning_customer_sk = cra.returning_customer_sk
  )                                                    AS web_return_sum_for_customer,
  cra.total_return_amount,
  cra.return_cnt
FROM catalog_return_agg cra
JOIN catalog_page cp
  ON cp.cp_catalog_page_sk = cra.cr_catalog_page_sk
JOIN date_dim d_ret
  ON cra.returned_date_sk = d_ret.d_date_sk                      -- returned date for catalog returns
JOIN ship_mode sm
  ON cra.ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_address ca_ret_addr
  ON cra.returning_addr_sk = ca_ret_addr.ca_address_sk
JOIN customer_demographics cd_ret
  ON cra.returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN store s
  ON s.s_closed_date_sk = d_ret.d_date_sk                         -- store closed on the same day (allowed rule)
JOIN date_dim d_store
  ON s.s_closed_date_sk = d_store.d_date_sk                       -- second alias for date_dim (reuse)
JOIN web_returns wr
  ON wr.wr_returned_date_sk = d_ret.d_date_sk                      -- web return on the same calendar day
JOIN date_dim d_wr
  ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_wp_creation
  ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN web_site ws
  ON ws.web_open_date_sk = d_wp_creation.d_date_sk
WHERE NOT EXISTS (
        SELECT 1
        FROM web_returns wr_check
        WHERE wr_check.wr_returning_customer_sk = cra.returning_customer_sk
      )
  AND cra.returning_customer_sk IN (SELECT cr_returning_customer_sk FROM catalog_only_customers)
GROUP BY
  d_ret.d_year,
  cp.cp_department,
  sm.sm_type,
  s.s_store_name,
  CASE
    WHEN cra.total_return_amount > 10000 THEN 'HIGH'
    ELSE 'LOW'
  END,
  cra.returning_customer_sk,
  cra.total_return_amount,
  cra.return_cnt
ORDER BY
  cra.total_return_amount DESC
LIMIT 100
