/*
  Goal:  Return a ranked list of stores (by cumulative net profit) for the year 2001, 
  including sample‑based sales aggregates, return aggregates, maximum sales price per store/day, 
  and holiday info.  The query demonstrates deep joins across all seven TPC‑DS tables, re‑uses 
  the DATE_DIM and STORE tables under different aliases, employs a TABLESAMPLE, a CROSS JOIN LATERAL, 
  a FULL OUTER JOIN, window functions, ordering, offset pagination and a final LIMIT.
*/
WITH
  -- 5% Bernoulli sample of store_sales to keep the query lightweight
  sampled_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (5)
  ),

  -- Sales aggregated per store and date (year = 2001)
  sales_agg AS (
    SELECT
      s.s_store_id,
      d.d_date_sk,
      d.d_year,
      SUM(ss.ss_net_profit) AS total_net_profit,
      COUNT(*) AS txn_count
    FROM sampled_sales ss
    JOIN date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE s.s_country = 'United States'
      AND d.d_year = 2001
    GROUP BY s.s_store_id, d.d_date_sk, d.d_year
  ),

  -- Returns aggregated per returned date (year = 2001) for the Electronics department
  returns_agg AS (
    SELECT
      d_ret.d_date_sk,
      d_ret.d_year,
      COUNT(*) AS return_cnt,
      SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    JOIN date_dim d_ret
      ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_demographics cd_ref
      ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN household_demographics hd_ref
      ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    WHERE cp.cp_department = 'Electronics'
      AND d_ret.d_year = 2001
    GROUP BY d_ret.d_date_sk, d_ret.d_year
  ),

  -- Store‑level lateral sub‑query to fetch the maximum sales price for each store/day
  store_lateral AS (
    SELECT
      s_lat.s_store_id,
      d_lat.d_date_sk,
      s_lat.s_number_employees,
      ml.max_price
    FROM store s_lat
    JOIN date_dim d_lat
      ON s_lat.s_closed_date_sk = d_lat.d_date_sk
    CROSS JOIN LATERAL (
      SELECT MAX(ss.ss_sales_price) AS max_price
      FROM store_sales ss
      WHERE ss.ss_store_sk = s_lat.s_store_sk
        AND ss.ss_sold_date_sk = d_lat.d_date_sk
    ) ml
    WHERE s_lat.s_state = 'CA'
  ),

  -- Full outer join between STORE and DATE_DIM to retain all stores and all dates
  full_dates AS (
    SELECT
      s_full.s_store_id,
      d_full.d_date_sk,
      s_full.s_number_employees,
      d_full.d_holiday
    FROM store s_full
    FULL OUTER JOIN date_dim d_full
      ON s_full.s_closed_date_sk = d_full.d_date_sk
  )

SELECT
  fd.s_store_id,
  fd.d_date_sk,
  fd.s_number_employees,
  fd.d_holiday,
  sa.total_net_profit,
  ra.return_cnt,
  ra.total_return_amount,
  sl.max_price,
  -- Cumulative profit per store ordered by date (window function)
  SUM(sa.total_net_profit) OVER (PARTITION BY fd.s_store_id ORDER BY fd.d_date_sk
                                 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_profit,
  -- Rank stores by total net profit for the selected year
  RANK() OVER (ORDER BY sa.total_net_profit DESC) AS profit_rank
FROM full_dates fd
LEFT JOIN sales_agg sa
  ON fd.s_store_id = sa.s_store_id
  AND fd.d_date_sk = sa.d_date_sk
LEFT JOIN returns_agg ra
  ON fd.d_date_sk = ra.d_date_sk
LEFT JOIN store_lateral sl
  ON fd.s_store_id = sl.s_store_id
  AND fd.d_date_sk = sl.d_date_sk
ORDER BY profit_rank
OFFSET 0
LIMIT 100
