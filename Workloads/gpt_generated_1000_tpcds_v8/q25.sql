WITH
  -- Union of web_page and promotion keys for an IN predicate
  unioned_key AS (
    SELECT wp.wp_web_page_sk AS id, wp.wp_type AS typ
    FROM web_page wp
    WHERE wp.wp_type = 'content'
    UNION ALL
    SELECT p.p_promo_sk AS id, p.p_promo_name AS typ
    FROM promotion p
    WHERE p.p_cost > 500
  ),
  -- Core join of the six selected tables with filters and aggregation
  main AS (
    SELECT
      d.d_date,
      d.d_year,
      d.d_month_seq,
      t.t_sub_shift,
      hd.hd_dep_count,
      hd.hd_vehicle_count,
      wp.wp_type,
      p.p_promo_name,
      SUM(wr.wr_return_amt)          AS total_return_amt,
      SUM(wr.wr_return_quantity)     AS total_return_qty
    FROM web_returns wr
      JOIN date_dim d       ON wr.wr_returned_date_sk = d.d_date_sk
      JOIN time_dim t       ON wr.wr_returned_time_sk = t.t_time_sk
      JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
      JOIN web_page wp      ON wr.wr_web_page_sk = wp.wp_web_page_sk
      JOIN promotion p      ON p.p_start_date_sk = d.d_date_sk
    WHERE
      d.d_year = 2001                         -- filter #1
      AND t.t_sub_shift = 'morning'           -- filter #2
      AND hd.hd_dep_count >= 6                -- filter #3
      AND wp.wp_type = 'content'              -- filter #4
      AND p.p_channel_radio = 'N'             -- filter #5
      AND wp.wp_web_page_sk IN (
            SELECT id FROM unioned_key WHERE typ = 'content'
          )
    GROUP BY
      d.d_date,
      d.d_year,
      d.d_month_seq,
      t.t_sub_shift,
      hd.hd_dep_count,
      hd.hd_vehicle_count,
      wp.wp_type,
      p.p_promo_name
  )
SELECT
  m.d_date,
  m.d_year,
  m.t_sub_shift,
  m.hd_dep_count,
  m.hd_vehicle_count,
  m.wp_type,
  m.p_promo_name,
  m.total_return_amt,
  m.total_return_qty,
  RANK() OVER (PARTITION BY m.d_year ORDER BY m.total_return_amt DESC)                AS year_rank,
  SUM(m.total_return_amt) OVER (PARTITION BY m.d_year ORDER BY m.d_month_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_return_amt,
  (SELECT MAX(p_cost) FROM promotion WHERE p_discount_active = 'Y')               AS max_promo_cost,
  CASE WHEN m.hd_vehicle_count > 2 THEN 'High' ELSE 'Low' END                    AS vehicle_level
FROM main m
ORDER BY
  m.d_year,
  m.d_date DESC
LIMIT 100
