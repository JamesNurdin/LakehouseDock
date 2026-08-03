/* Goal: Compare total web return amounts per year and store, excluding stores managed by John Mccoy, using cube aggregation, case‑based high‑credit counts, and set subtraction. */
WITH
  wr_agg AS (
    SELECT
      wr_returned_date_sk,
      SUM(wr_return_amt)                         AS total_return_amt,
      SUM(wr_return_quantity)                    AS total_return_qty,
      COUNT(*)                                   AS cnt_returns,
      SUM(CASE WHEN wr_account_credit > 100 THEN 1 ELSE 0 END) AS high_credit_cnt
    FROM web_returns
    WHERE wr_returned_date_sk IS NOT NULL
      AND wr_return_quantity > 0
      AND wr_return_amt > 0
      AND wr_account_credit >= 0
      AND wr_return_tax >= 0
    GROUP BY wr_returned_date_sk
  ),

  joined AS (
    SELECT
      d.d_date_sk,
      d.d_year,
      d.d_month_seq,
      d.d_current_week,
      s.s_store_id,
      s.s_state,
      s.s_manager,
      s.s_tax_percentage,
      w.total_return_amt,
      w.total_return_qty,
      w.cnt_returns,
      w.high_credit_cnt
    FROM date_dim d
    INNER JOIN wr_agg w ON w.wr_returned_date_sk = d.d_date_sk
    INNER JOIN store s   ON s.s_closed_date_sk    = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1200 AND 1300
      AND d.d_current_week = 'N'
      AND s.s_state = 'CA'
      AND s.s_tax_percentage > 5.00
  ),

  agg_cubed AS (
    SELECT
      d_year,
      s_store_id,
      SUM(total_return_amt) AS sum_return_amt,
      SUM(total_return_qty) AS sum_return_qty,
      SUM(cnt_returns)      AS sum_returns,
      SUM(high_credit_cnt)  AS sum_high_credit
    FROM joined
    GROUP BY CUBE (d_year, s_store_id)
  ),

  agg_exclude AS (
    SELECT
      d_year,
      s_store_id,
      SUM(total_return_amt) AS sum_return_amt,
      SUM(total_return_qty) AS sum_return_qty,
      SUM(cnt_returns)      AS sum_returns,
      SUM(high_credit_cnt)  AS sum_high_credit
    FROM joined
    WHERE s_manager = 'John Mccoy'
    GROUP BY CUBE (d_year, s_store_id)
  ),

  final_result AS (
    SELECT * FROM agg_cubed
    EXCEPT
    SELECT * FROM agg_exclude
  )
SELECT
  d_year,
  s_store_id,
  sum_return_amt,
  sum_return_qty,
  sum_returns,
  sum_high_credit
FROM final_result
ORDER BY d_year NULLS LAST, s_store_id
LIMIT 100
