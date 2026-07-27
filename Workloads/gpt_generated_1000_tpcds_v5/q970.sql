WITH
  high_returns AS (
    SELECT
      c.c_customer_id,
      c.c_first_name,
      c.c_last_name,
      SUM(sr.sr_return_amt) AS total_return_amt,
      COUNT(*) AS return_cnt,
      CASE
        WHEN SUM(sr.sr_return_amt) > 500 THEN 'Platinum'
        WHEN SUM(sr.sr_return_amt) > 200 THEN 'Gold'
        ELSE 'Silver'
      END AS tier,
      ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(sr.sr_return_amt) DESC) AS rn
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE sr.sr_return_amt > 100
      AND EXISTS (
        SELECT 1
        FROM household_demographics hd2
        WHERE hd2.hd_demo_sk = c.c_current_hdemo_sk
          AND hd2.hd_vehicle_count > 2
      )
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
    HAVING COUNT(*) >= 2
  ),
  low_returns AS (
    SELECT DISTINCT
      c.c_customer_id,
      c.c_first_name,
      c.c_last_name,
      SUM(sr.sr_return_amt) AS total_return_amt,
      COUNT(*) AS return_cnt,
      CASE
        WHEN SUM(sr.sr_return_amt) < 20 THEN 'Low'
        ELSE 'Medium'
      END AS tier,
      ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(sr.sr_return_amt)) AS rn
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE sr.sr_return_amt < 50
      AND hd.hd_dep_count <= 2
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
    HAVING COUNT(*) >= 1
  )
SELECT *
FROM high_returns
UNION ALL
SELECT *
FROM low_returns
ORDER BY total_return_amt DESC
LIMIT 100
