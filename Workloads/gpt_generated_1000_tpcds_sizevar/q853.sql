WITH
  -- 10% Bernoulli sample of store returns
  sampled_store AS (
    SELECT *
    FROM store_returns
    TABLESAMPLE BERNOULLI (10)
  ),

  -- Pre‑aggregate sampled store returns by customer demographic and return date
  store_agg AS (
    SELECT
      sr_cdemo_sk AS cd_demo_sk,
      sr_returned_date_sk AS return_date_sk,
      SUM(sr_return_amt) AS store_return_sum,
      COUNT(*)        AS store_return_cnt
    FROM sampled_store
    WHERE sr_return_amt > 20.00                 -- predicate 1
      AND sr_return_tax BETWEEN 1.00 AND 5.00   -- predicate 2
    GROUP BY sr_cdemo_sk, sr_returned_date_sk
  ),

  -- Pre‑aggregate web returns (refunded side) by customer demographic and return date
  web_agg AS (
    SELECT
      wr_refunded_cdemo_sk AS cd_demo_sk,
      wr_returned_date_sk AS return_date_sk,
      SUM(wr_return_amt) AS web_return_sum,
      COUNT(*)          AS web_return_cnt
    FROM web_returns
    WHERE wr_return_amt > 15.00                 -- predicate 3
      AND wr_return_tax < 4.00                  -- predicate 4
    GROUP BY wr_refunded_cdemo_sk, wr_returned_date_sk
  ),

  -- Intersection of customer keys that appear in both store and web aggregates
  intersect_keys AS (
    SELECT cd_demo_sk
    FROM store_agg
    INTERSECT
    SELECT cd_demo_sk
    FROM web_agg
  ),

  -- Customer keys that appear in store aggregates but not in web aggregates
  except_keys AS (
    SELECT cd_demo_sk
    FROM store_agg
    EXCEPT
    SELECT cd_demo_sk
    FROM web_agg
  ),

  -- Join the aggregates with demographic and date dimensions and apply rich filters
  joined AS (
    SELECT
      cd.cd_demo_sk,
      d.d_year,
      d.d_month_seq,
      d.d_day_name,
      sa.store_return_sum,
      wa.web_return_sum,
      (sa.store_return_sum + wa.web_return_sum) AS total_return,
      cd.cd_purchase_estimate,
      cd.cd_gender,
      cd.cd_marital_status,
      cd.cd_dep_employed_count,
      cd.cd_dep_count
    FROM store_agg sa
    JOIN web_agg wa
      ON sa.cd_demo_sk = wa.cd_demo_sk
     AND sa.return_date_sk = wa.return_date_sk
    JOIN customer_demographics cd
      ON cd.cd_demo_sk = sa.cd_demo_sk
    JOIN date_dim d
      ON d.d_date_sk = sa.return_date_sk
    WHERE cd.cd_gender = 'M'                                 -- predicate 5
      AND cd.cd_marital_status = 'M'                         -- predicate 6
      AND cd.cd_purchase_estimate BETWEEN 2000 AND 9000    -- predicate 7
      AND cd.cd_dep_employed_count = 3                      -- predicate 8
      AND cd.cd_dep_count > 1                               -- predicate 9
      AND d.d_year = 2001                                    -- predicate 10
      AND d.d_month_seq BETWEEN 1 AND 12                     
      AND d.d_day_name = 'Monday'
  ),

  -- Final projection with window functions and flags for intersect / except
  final AS (
    SELECT
      j.d_year,
      j.d_month_seq,
      j.cd_demo_sk,
      j.total_return,
      j.store_return_sum,
      j.web_return_sum,
      -- Running count of rows per year ordered by total_return descending
      COUNT(*) OVER (PARTITION BY j.d_year ORDER BY j.total_return DESC
                     ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_cnt,
      -- Cumulative total_return per year
      SUM(j.total_return) OVER (PARTITION BY j.d_year ORDER BY j.total_return DESC
                                ROWS UNBOUNDED PRECEDING) AS running_total_return,
      CASE WHEN j.cd_demo_sk IN (SELECT cd_demo_sk FROM intersect_keys) THEN 1 ELSE 0 END AS in_intersect,
      CASE WHEN j.cd_demo_sk IN (SELECT cd_demo_sk FROM except_keys)   THEN 1 ELSE 0 END AS in_except
    FROM joined j
  )
SELECT
  d_year,
  d_month_seq,
  cd_demo_sk,
  total_return,
  store_return_sum,
  web_return_sum,
  running_cnt,
  running_total_return,
  in_intersect,
  in_except
FROM final
ORDER BY d_year DESC, total_return DESC
LIMIT 100
