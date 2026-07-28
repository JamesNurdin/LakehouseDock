/*
Goal: Analyze the financial impact of catalog returns by warehouse, ship mode and return reason, together with a comparable sales aggregation, using deep joins, reused dimension tables, a left outer join, scalar subqueries and grouping sets to produce subtotal rows.
*/
WITH
  -- Returns side joins the catalog_returns fact to customers, two household‑demographic roles, ship mode (left), warehouse and reason.
  returns AS (
    SELECT
      cr.cr_returned_date_sk,
      cr.cr_return_amount,
      cr.cr_net_loss,
      c_ret.c_customer_id            AS returning_customer_id,
      hd_ret.hd_income_band_sk       AS returning_income_band_sk,
      sm.sm_ship_mode_id             AS ship_mode_id,
      w.w_warehouse_id               AS warehouse_id,
      r.r_reason_desc                AS reason_desc,
      c_ref.c_customer_id            AS refunded_customer_id,
      hd_ref.hd_income_band_sk       AS refunded_income_band_sk
    FROM catalog_returns cr
    JOIN customer c_ret
      ON cr.cr_returning_customer_sk = c_ret.c_customer_sk                     /* join 1 */
    JOIN household_demographics hd_ret
      ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk                           /* join 2 */
    LEFT JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk                                 /* join 3 (left) */
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk                                   /* join 4 */
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk                                         /* join 5 */
    JOIN customer c_ref
      ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk                        /* join 6 */
    JOIN household_demographics hd_ref
      ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk                             /* join 7 */
  ),
  -- Sales side joins the store_sales fact to customer and household_demographics.
  sales AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_sales_price,
      ss.ss_ext_sales_price,
      c.c_customer_id               AS sales_customer_id,
      hd.hd_income_band_sk          AS sales_income_band_sk,
      ss.ss_store_sk                AS store_sk
    FROM store_sales ss
    JOIN customer c
      ON ss.ss_customer_sk = c.c_customer_sk                                 /* join 8 */
    JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk                                      /* join 9 */
  )
SELECT * FROM (
  -- Returns aggregation with grouping sets (warehouse → ship mode → reason hierarchy)
  SELECT
    CAST('Return' AS VARCHAR)                AS activity_type,
    r.warehouse_id,
    r.ship_mode_id,
    r.reason_desc,
    SUM(r.cr_net_loss)                      AS total_amount,
    (SELECT AVG(cr_return_amount) FROM catalog_returns) AS avg_amount
  FROM returns r
  GROUP BY GROUPING SETS (
    (r.warehouse_id, r.ship_mode_id, r.reason_desc),
    (r.warehouse_id, r.ship_mode_id),
    (r.warehouse_id),
    ()
  )
  UNION ALL
  -- Sales aggregation – only store‑level subtotal (store_sk) and grand total
  SELECT
    CAST('Sale' AS VARCHAR)                  AS activity_type,
    NULL                                      AS warehouse_id,
    NULL                                      AS ship_mode_id,
    NULL                                      AS reason_desc,
    SUM(s.ss_ext_sales_price)                AS total_amount,
    (SELECT AVG(ss_sales_price) FROM store_sales) AS avg_amount
  FROM sales s
  GROUP BY GROUPING SETS (
    (s.store_sk),
    ()
  )
) AS combined
ORDER BY
  activity_type,
  warehouse_id,
  ship_mode_id,
  reason_desc,
  total_amount DESC
