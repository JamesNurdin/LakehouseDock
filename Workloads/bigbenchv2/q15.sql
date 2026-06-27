WITH
  /* ---------------------------------------------------------------
   * 1️⃣  Parameters – change the literals if you need a different
   *     window or store.
   * --------------------------------------------------------------- */
  params AS (
    SELECT
      DATE '2013-09-02' AS start_date,
      DATE '2014-09-02' AS end_date,
      10                AS store_id   -- stores are numbered 1‑12
  ),

  /* ---------------------------------------------------------------
   * 2️⃣  Sales per second (epoch) per category for the chosen store
   *     and period.
   *     x = Unix epoch (seconds) of the transaction timestamp.
   *     y = Total sales amount for that timestamp & category.
   * --------------------------------------------------------------- */
  sales_per_ts AS (
    SELECT
      i.i_category_id                     AS cat,
      CAST(to_unixtime(CAST(s.ss_ts AS TIMESTAMP)) AS BIGINT) AS x,
      SUM(s.ss_quantity * i.i_price)      AS y
    FROM store_sales s
    JOIN items i ON s.ss_item_id = i.i_item_id
    CROSS JOIN params p                     -- bring the parameters into scope
    WHERE i.i_category_id IS NOT NULL
      AND s.ss_store_id = p.store_id
      AND DATE(CAST(s.ss_ts AS TIMESTAMP)) BETWEEN p.start_date AND p.end_date
    GROUP BY i.i_category_id,
             CAST(to_unixtime(CAST(s.ss_ts AS TIMESTAMP)) AS BIGINT)
  ),

  /* ---------------------------------------------------------------
   * 3️⃣  Aggregate the values needed for ordinary‑least‑squares
   *     regression (slope & intercept).
   * --------------------------------------------------------------- */
  agg AS (
    SELECT
      cat,
      COUNT(*)                                 AS n,
      SUM(x)                                    AS sum_x,
      SUM(y)                                    AS sum_y,
      SUM(x * y)                                AS sum_xy,
      SUM(x * x)                                AS sum_xx
    FROM sales_per_ts
    GROUP BY cat
  ),

  /* ---------------------------------------------------------------
   * 4️⃣  Compute slope and intercept for each category.  Guard
   *     against a zero denominator (which would happen if all x‑
   *     values are the same).
   * --------------------------------------------------------------- */
  regression AS (
    SELECT
      cat,
      CASE
        WHEN (n * sum_xx - sum_x * sum_x) = 0 THEN 0.0
        ELSE (n * sum_xy - sum_x * sum_y) / (n * sum_xx - sum_x * sum_x)
      END AS slope,
      CASE
        WHEN n = 0 THEN 0.0
        ELSE (sum_y - (
               CASE
                 WHEN (n * sum_xx - sum_x * sum_x) = 0 THEN 0.0
                 ELSE (n * sum_xy - sum_x * sum_y) / (n * sum_xx - sum_x * sum_x)
               END
             ) * sum_x) / n
      END AS intercept
    FROM agg
  )
/* ---------------------------------------------------------------
 * 5️⃣  Final result – only categories whose slope is negative (flat
 *     or declining sales).  The column order matches the original
 *     Hive result table (cat, slope, intercept).
 * --------------------------------------------------------------- */
SELECT
  cat,
  slope,
  intercept
FROM regression
WHERE slope < 0
ORDER BY cat
