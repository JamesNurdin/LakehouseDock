WITH
  store_returns_agg AS (
    SELECT
      sr.sr_store_sk,
      COUNT(DISTINCT sr.sr_customer_sk) AS distinct_customers,
      SUM(sr.sr_return_amt) AS total_return_amt
    FROM tpcds.store_returns sr
    WHERE sr.sr_return_amt > 100
    GROUP BY sr.sr_store_sk
  ),
  store_filtered AS (
    SELECT
      s.s_store_sk,
      s.s_store_name,
      s.s_rec_start_date
    FROM tpcds.store s
    WHERE s.s_rec_start_date >= DATE '2020-01-01'
      AND EXISTS (
        SELECT 1
        FROM tpcds.store_returns sr2
        WHERE sr2.sr_store_sk = s.s_store_sk
          AND sr2.sr_return_amt > 200
      )
  ),
  full_join AS (
    SELECT
      COALESCE(s.s_store_sk, ra.sr_store_sk) AS store_sk,
      s.s_store_name,
      ra.distinct_customers,
      ra.total_return_amt
    FROM store_filtered s
    FULL OUTER JOIN store_returns_agg ra
      ON s.s_store_sk = ra.sr_store_sk
  ),
  high_exclusive_customers AS (
    SELECT sr_customer_sk
    FROM (
      SELECT DISTINCT sr_customer_sk
      FROM tpcds.store_returns
      WHERE sr_return_amt > 500
    ) hi
    EXCEPT
    SELECT DISTINCT sr_customer_sk
    FROM tpcds.store_returns
    WHERE sr_return_amt <= 500
  )
SELECT
  COUNT(DISTINCT result.store_sk) AS distinct_store_count,
  COUNT(DISTINCT result.total_return_amt) AS distinct_return_amounts,
  (SELECT COUNT(*) FROM high_exclusive_customers) AS exclusive_high_customer_cnt
FROM (
  SELECT store_sk, s_store_name, total_return_amt
  FROM (
    SELECT store_sk, s_store_name, total_return_amt
    FROM full_join
    WHERE total_return_amt > 1000
  ) a
  EXCEPT
  SELECT store_sk, s_store_name, total_return_amt
  FROM (
    SELECT store_sk, s_store_name, total_return_amt
    FROM full_join
    WHERE total_return_amt < 200
  ) b
) result
ORDER BY distinct_store_count DESC
OFFSET 0 ROWS
LIMIT 100
