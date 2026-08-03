WITH
  a AS (
    SELECT st.s_store_sk
    FROM store_sales ss
    JOIN store st ON ss.ss_store_sk = st.s_store_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 12
      AND ss.ss_net_profit > 1000
    GROUP BY st.s_store_sk
  ),
  b AS (
    SELECT st.s_store_sk
    FROM store_returns sr
    JOIN store st ON sr.sr_store_sk = st.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%defect%'
      AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_store_sk = st.s_store_sk
          AND sr2.sr_return_quantity > 10
      )
    GROUP BY st.s_store_sk
    HAVING SUM(sr.sr_net_loss) > 500
  ),
  c AS (
    SELECT st.s_store_sk
    FROM store st
    WHERE st.s_state = 'CA'
      AND st.s_number_employees > 200
  ),
  intersect_plus AS (
    SELECT a.s_store_sk
    FROM a
    INTERSECT
    SELECT b.s_store_sk
    FROM b
  )
SELECT
  t.s_store_sk,
  st.s_store_name,
  (
    SELECT SUM(ss3.ss_net_profit)
    FROM store_sales ss3
    WHERE ss3.ss_store_sk = t.s_store_sk
  ) AS total_net_profit
FROM (
  SELECT ip.s_store_sk
  FROM intersect_plus ip
  EXCEPT
  SELECT c.s_store_sk
  FROM c
) AS t
JOIN store st ON t.s_store_sk = st.s_store_sk
ORDER BY total_net_profit DESC
OFFSET 0 FETCH FIRST 100 ROWS ONLY
