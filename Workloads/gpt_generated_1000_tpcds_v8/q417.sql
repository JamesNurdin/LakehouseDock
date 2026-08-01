/*
  Goal: Provide a state‑level view of return activity combining store and catalog returns, 
  enriched with customer demographics, income bands and call‑center / ship‑mode information. 
  The query demonstrates complex Trino features: full outer join, multiple join paths, 
  selective predicates, aggregation, DISTINCT, UNION (dedup), INTERSECT, correlated scalar subqueries, 
  and final ordering with a LIMIT.
*/
WITH
  /* Full outer join between Customer and its current address – keeps customers without an address and vice‑versa */
  cust_addr AS (
    SELECT
      c.c_customer_sk,
      c.c_customer_id,
      c.c_current_cdemo_sk,
      c.c_current_hdemo_sk,
      c.c_current_addr_sk,
      ca.ca_address_sk,
      ca.ca_state,
      ca.ca_country
    FROM
      customer c
      FULL OUTER JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
  ),

  /* Customers that appear in BOTH store_returns and catalog_returns */
  intersect_customers AS (
    SELECT c.c_customer_id
    FROM store_returns sr
      JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    INTERSECT
    SELECT c.c_customer_id
    FROM catalog_returns cr
      JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
  ),

  /* Store‑return side – aggregated per state */
  store_part AS (
    SELECT
      ca.ca_state AS state,
      SUM(sr.sr_return_amt)         AS store_return_total,
      COUNT(*)                      AS store_return_cnt
    FROM
      store_returns sr
      JOIN cust_addr ca
        ON sr.sr_customer_sk = ca.c_customer_sk
        AND sr.sr_addr_sk    = ca.ca_address_sk
      JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
      JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
      JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
      ca.ca_state = 'CA'
      AND hd.hd_vehicle_count > 2
      AND ib.ib_lower_bound >= 50000
      AND sr.sr_return_quantity > 1
    GROUP BY
      ca.ca_state
  ),

  /* Catalog‑return side – aggregated per state */
  catalog_part AS (
    SELECT
      ca.ca_state AS state,
      SUM(cr.cr_return_amount)      AS catalog_return_total,
      COUNT(*)                      AS catalog_return_cnt
    FROM
      catalog_returns cr
      JOIN cust_addr ca
        ON cr.cr_refunded_customer_sk = ca.c_customer_sk
        AND cr.cr_refunded_addr_sk   = ca.ca_address_sk
      JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
      JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
      JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
      JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
      JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
      cc.cc_state = 'CA'
      AND sm.sm_carrier = 'AIRBORNE'
      AND cr.cr_return_amount > 100
      AND cr.cr_return_quantity > 1
    GROUP BY
      ca.ca_state
  ),

  /* Union of the two side‑by‑side aggregates – DISTINCT (default for UNION) */
  unified AS (
    SELECT state, store_return_total, 0 AS catalog_return_total
    FROM store_part
    UNION
    SELECT state, 0, catalog_return_total
    FROM catalog_part
  )

SELECT DISTINCT
  u.state,
  SUM(u.store_return_total)   AS total_store_return,
  SUM(u.catalog_return_total) AS total_catalog_return,
  COUNT(*)                     AS contributing_rows,
  -- Correlated scalar subquery: average store return amount for the state
  (SELECT AVG(sr2.sr_return_amt)
     FROM store_returns sr2
     JOIN customer c2 ON sr2.sr_customer_sk = c2.c_customer_sk
     JOIN customer_address ca2 ON c2.c_current_addr_sk = ca2.ca_address_sk
    WHERE ca2.ca_state = u.state)               AS avg_store_return_amt_by_state,
  -- Count of customers that appear in both return streams for the state
  (SELECT COUNT(*)
     FROM intersect_customers ic
     JOIN customer c3 ON ic.c_customer_id = c3.c_customer_id
     JOIN customer_address ca3 ON c3.c_current_addr_sk = ca3.ca_address_sk
    WHERE ca3.ca_state = u.state)               AS intersect_customer_cnt
FROM
  unified u
GROUP BY
  u.state
ORDER BY
  total_store_return DESC,
  total_catalog_return DESC
LIMIT 100
