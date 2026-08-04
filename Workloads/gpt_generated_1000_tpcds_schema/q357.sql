WITH
  /* Base join that touches all selected tables and re‑uses several of them */
  base AS (
    SELECT
      cs.cs_order_number,
      cs.cs_net_paid,
      cs.cs_sold_date_sk,
      cs.cs_ship_date_sk,
      d_sale.d_year AS sale_year,
      d_ship.d_year AS ship_year,
      d_return.d_year AS return_year,
      cc.cc_name,
      cc_ret.cc_name AS cc_ret_name,
      cp.cp_department,
      cp_ret.cp_department AS cp_ret_department,
      sm.sm_type,
      sm_ret.sm_type AS sm_ret_type,
      p.p_promo_name,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      cd_ref.cd_gender AS refunded_gender,
      cd_ret.cd_gender AS returning_gender,
      s.s_store_name,
      d_store_closed.d_year AS store_closed_year
    FROM catalog_sales cs
    /* date_dim for sale and ship dates */
    JOIN date_dim d_sale ON cs.cs_sold_date_sk = d_sale.d_date_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    /* call center that originated the sale */
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    /* catalog page of the item */
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    /* shipping mode */
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    /* promotion applied */
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    /* household demographics linked to the billing household */
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    /* join the corresponding return record (if any) */
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN date_dim d_return ON cr.cr_returned_date_sk = d_return.d_date_sk
    /* return‑side dimensions – reused tables with different aliases */
    LEFT JOIN call_center cc_ret ON cr.cr_call_center_sk = cc_ret.cc_call_center_sk
    LEFT JOIN catalog_page cp_ret ON cr.cr_catalog_page_sk = cp_ret.cp_catalog_page_sk
    LEFT JOIN ship_mode sm_ret ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
    LEFT JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    LEFT JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    /* store – linked through its closed‑date surrogate */
    JOIN store s ON s.s_closed_date_sk = d_sale.d_date_sk
    JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
  ),
  /* Derive each order's income‑band (used later) */
  order_income AS (
    SELECT DISTINCT cs_order_number, hd_income_band_sk
    FROM base
  ),
  /* Small dimension cross‑joined with a computed set (two dummy rows) */
  cross_part AS (
    SELECT ib.ib_income_band_sk, v.grp
    FROM income_band ib
    CROSS JOIN (VALUES (1), (2)) AS v(grp)
  ),
  /* Aggregation 1 – sales in year 1999, filtered by a HAVING clause */
  agg1 AS (
    SELECT cs_order_number,
           SUM(cs_net_paid) AS total_paid
    FROM base
    WHERE sale_year = 1999
    GROUP BY cs_order_number
    HAVING SUM(cs_net_paid) > 1000
  ),
  /* Aggregation 2 – shipments in year 1999, filtered by a HAVING clause */
  agg2 AS (
    SELECT cs_order_number,
           SUM(cs_net_paid) AS total_paid
    FROM base
    WHERE ship_year = 1999
    GROUP BY cs_order_number
    HAVING SUM(cs_net_paid) > 1000
  ),
  /* UNION of the two aggregated key sets (distinct) */
  union_set AS (
    SELECT cs_order_number FROM agg1
    UNION
    SELECT cs_order_number FROM agg2
  ),
  /* INTERSECT of the two aggregated key sets */
  intersect_set AS (
    SELECT cs_order_number FROM agg1
    INTERSECT
    SELECT cs_order_number FROM agg2
  )
SELECT
  u.cs_order_number,
  i.cs_order_number AS intersect_order,
  cp.ib_income_band_sk,
  cp.grp,
  a1.total_paid AS agg1_paid,
  a2.total_paid AS agg2_paid
FROM union_set u
JOIN intersect_set i ON u.cs_order_number = i.cs_order_number
JOIN order_income oi ON u.cs_order_number = oi.cs_order_number
JOIN cross_part cp ON oi.hd_income_band_sk = cp.ib_income_band_sk
LEFT JOIN agg1 a1 ON u.cs_order_number = a1.cs_order_number
LEFT JOIN agg2 a2 ON u.cs_order_number = a2.cs_order_number
GROUP BY
  u.cs_order_number,
  i.cs_order_number,
  cp.ib_income_band_sk,
  cp.grp,
  a1.total_paid,
  a2.total_paid
HAVING COUNT(*) = 1
ORDER BY u.cs_order_number
LIMIT 100
