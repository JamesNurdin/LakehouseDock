/* goal: Identify high‑revenue brand‑year combinations by combining store, web and catalog return data, flagging revenue buckets, ranking brands, and showing customers that bought both in‑store and online versus only in‑store. The query demonstrates joins across all eight TPC‑DS tables, uses ROLLUP for subtotals, applies five filter predicates, computes distinct aggregates, employs INTERSECT and EXCEPT, includes a RIGHT OUTER JOIN to retain all ship modes, and finishes with a window rank and a LIMIT. */
WITH
  /* Store sales aggregation */
  store_agg AS (
    SELECT
      d.d_year,
      i.i_brand,
      cd.cd_demo_sk,
      SUM(ss.ss_net_paid)                         AS store_net_paid,
      COUNT(DISTINCT ss.ss_item_sk)                AS distinct_store_items,
      SUM(CASE WHEN ss.ss_net_profit > 1000 THEN 1 ELSE 0 END) AS high_profit_txn
    FROM store_sales ss
    JOIN date_dim d       ON ss.ss_sold_date_sk   = d.d_date_sk
    JOIN time_dim t       ON ss.ss_sold_time_sk   = t.t_time_sk
    JOIN item i           ON ss.ss_item_sk        = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE
      d.d_year BETWEEN 2000 AND 2002               /* predicate 1 */
      AND ss.ss_quantity > 5                       /* predicate 2 */
      AND i.i_current_price > 20                   /* predicate 3 */
      AND cd.cd_credit_rating IN ('Good','High Risk') /* predicate 4 */
      AND t.t_hour BETWEEN 8 AND 18               /* predicate 5 */
    GROUP BY ROLLUP (d.d_year, i.i_brand, cd.cd_demo_sk)
  ),

  /* Web sales aggregation */
  web_agg AS (
    SELECT
      d.d_year,
      i.i_brand,
      sm.sm_ship_mode_sk,
      SUM(ws.ws_net_paid)                         AS web_net_paid,
      COUNT(DISTINCT ws.ws_item_sk)                AS distinct_web_items,
      SUM(CASE WHEN ws.ws_net_profit > 2000 THEN 1 ELSE 0 END) AS high_profit_txn_ws
    FROM web_sales ws
    JOIN date_dim d       ON ws.ws_sold_date_sk   = d.d_date_sk
    JOIN time_dim t       ON ws.ws_sold_time_sk   = t.t_time_sk
    JOIN item i           ON ws.ws_item_sk        = i.i_item_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN ship_mode sm    ON ws.ws_ship_mode_sk   = sm.sm_ship_mode_sk
    WHERE
      d.d_year BETWEEN 2000 AND 2002               /* predicate 1 */
      AND ws.ws_quantity > 5                       /* predicate 2 */
      AND i.i_current_price > 20                   /* predicate 3 */
      AND cd.cd_credit_rating = 'Good'            /* predicate 4 */
      AND sm.sm_type = 'AIR'                       /* predicate 5 */
    GROUP BY ROLLUP (d.d_year, i.i_brand, sm.sm_ship_mode_sk)
  ),

  /* Catalog returns aggregation */
  returns_agg AS (
    SELECT
      d.d_year,
      i.i_brand,
      cr.cr_ship_mode_sk,
      SUM(cr.cr_net_loss)                         AS return_net_loss,
      COUNT(DISTINCT cr.cr_item_sk)                AS distinct_return_items
    FROM catalog_returns cr
    JOIN date_dim d       ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t       ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i           ON cr.cr_item_sk          = i.i_item_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN ship_mode sm    ON cr.cr_ship_mode_sk     = sm.sm_ship_mode_sk
    WHERE
      d.d_year BETWEEN 2000 AND 2002               /* predicate 1 */
      AND cr.cr_return_quantity > 0                /* predicate 2 */
      AND i.i_current_price > 20                   /* predicate 3 */
      AND cd.cd_credit_rating = 'Good'            /* predicate 4 */
      AND sm.sm_type = 'AIR'                       /* predicate 5 */
    GROUP BY ROLLUP (d.d_year, i.i_brand, cr.cr_ship_mode_sk)
  ),

  /* Customers that bought both in‑store and online */
  intersect_cust AS (
    SELECT cd_demo_sk FROM store_sales ss
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE ss.ss_quantity > 5
    INTERSECT
    SELECT cd_demo_sk FROM web_sales ws
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE ws.ws_quantity > 5
  ),

  /* Customers that bought only in‑store (store EXCEPT web) */
  except_cust AS (
    SELECT cd_demo_sk FROM store_sales ss
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE ss.ss_quantity > 5
    EXCEPT
    SELECT cd_demo_sk FROM web_sales ws
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE ws.ws_quantity > 5
  )
SELECT
  sa.d_year,
  sa.i_brand,
  sa.cd_demo_sk,
  sa.store_net_paid,
  wa.web_net_paid,
  ra.return_net_loss,
  sa.distinct_store_items,
  wa.distinct_web_items,
  CASE WHEN (sa.store_net_paid + wa.web_net_paid - ra.return_net_loss) > 5000 THEN 'High' ELSE 'Medium' END AS revenue_bucket,
  RANK() OVER (PARTITION BY sa.i_brand ORDER BY (sa.store_net_paid + wa.web_net_paid - ra.return_net_loss) DESC) AS brand_rank,
  COUNT(DISTINCT sa.cd_demo_sk) OVER (PARTITION BY sa.i_brand) AS distinct_customers_in_brand
FROM store_agg sa
LEFT JOIN web_agg wa   ON sa.d_year = wa.d_year AND sa.i_brand = wa.i_brand
LEFT JOIN returns_agg ra ON sa.d_year = ra.d_year AND sa.i_brand = ra.i_brand
LEFT JOIN intersect_cust ic ON sa.cd_demo_sk = ic.cd_demo_sk
LEFT JOIN except_cust ec   ON sa.cd_demo_sk = ec.cd_demo_sk
RIGHT JOIN ship_mode sm   ON ra.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE
  sm.sm_type = 'AIR'                    -- keep only AIR ship mode rows
  AND (sa.store_net_paid > 1000 OR wa.web_net_paid > 1000)  -- additional filter
  AND ra.return_net_loss IS NOT NULL   -- ensure return data exists
ORDER BY revenue_bucket DESC, brand_rank
LIMIT 100
