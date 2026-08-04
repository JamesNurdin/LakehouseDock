/*
  Goal: Identify top entities (stores and call centers) by total sales, applying string pattern filters on names and locations, extracting promotional text, and demonstrating advanced SQL features such as regex, LIKE, concatenation, CTEs, UNION, lateral subqueries, scalar subqueries, and window functions.
*/
WITH
  /* Aggregate store sales with necessary attributes */
  store_sales_agg AS (
    SELECT
      s.s_store_sk,
      s.s_store_name,
      s.s_city,
      p.p_discount_active,
      d.d_year,
      SUM(ss.ss_ext_sales_price)          AS total_sales,
      SUM(ss.ss_ext_discount_amt)         AS total_discount,
      MAX(ss.ss_promo_sk)                 AS promo_sk
    FROM store_sales ss
    JOIN date_dim d   ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s       ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p   ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY
      s.s_store_sk,
      s.s_store_name,
      s.s_city,
      p.p_discount_active,
      d.d_year
  ),
  /* Aggregate catalog sales with needed keys */
  catalog_sales_agg AS (
    SELECT
      cc.cc_call_center_sk,
      cc.cc_name,
      cc.cc_state,
      p.p_promo_sk,
      d.d_year,
      SUM(cs.cs_ext_sales_price)      AS total_sales,
      SUM(cs.cs_ext_discount_amt)     AS total_discount
    FROM catalog_sales cs
    JOIN date_dim d          ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p         ON cs.cs_promo_sk = p.p_promo_sk
    GROUP BY
      cc.cc_call_center_sk,
      cc.cc_name,
      cc.cc_state,
      p.p_promo_sk,
      d.d_year
  )
SELECT
  final.entity_name,
  final.year,
  final.total_sales,
  final.total_discount,
  final.avg_discount,
  final.max_promo_cost,
  final.rn
FROM (
  /* First branch – stores */
  SELECT
    ssa.s_store_name            AS entity_name,
    ssa.d_year                  AS year,
    ssa.total_sales,
    ssa.total_discount,
    ld.avg_discount,
    (SELECT MAX(p2.p_cost) FROM promotion p2) AS max_promo_cost,
    ROW_NUMBER() OVER (ORDER BY ssa.total_sales DESC) AS rn
  FROM store_sales_agg ssa
  JOIN store s                ON ssa.s_store_sk = s.s_store_sk
  JOIN promotion p            ON ssa.promo_sk = p.p_promo_sk
  CROSS JOIN LATERAL (
    SELECT AVG(ss2.ss_ext_discount_amt) AS avg_discount
    FROM store_sales ss2
    WHERE ss2.ss_store_sk = ssa.s_store_sk
  ) ld
  WHERE REGEXP_LIKE(s.s_store_name, 'Store')
    AND s.s_city LIKE '%York%'
    AND p.p_discount_active = 'Y'

  UNION DISTINCT

  /* Second branch – call centers */
  SELECT
    csa.cc_name                AS entity_name,
    csa.d_year                 AS year,
    csa.total_sales,
    csa.total_discount,
    ld2.avg_discount,
    (SELECT MAX(p3.p_cost) FROM promotion p3) AS max_promo_cost,
    ROW_NUMBER() OVER (ORDER BY csa.total_sales DESC) AS rn
  FROM catalog_sales_agg csa
  JOIN call_center cc          ON csa.cc_call_center_sk = cc.cc_call_center_sk
  JOIN promotion p             ON csa.p_promo_sk = p.p_promo_sk
  CROSS JOIN LATERAL (
    SELECT AVG(cs2.cs_ext_discount_amt) AS avg_discount
    FROM catalog_sales cs2
    WHERE cs2.cs_call_center_sk = csa.cc_call_center_sk
  ) ld2
  WHERE REGEXP_EXTRACT(p.p_promo_name, '^([A-Za-z]+)', 1) = 'Holiday'
    AND cc.cc_state LIKE 'CA%'
) final
ORDER BY final.total_sales DESC
LIMIT 100
