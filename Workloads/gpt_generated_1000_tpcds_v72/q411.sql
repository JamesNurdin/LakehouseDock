WITH
  store_reason AS (
    SELECT r.r_reason_id,
           r.r_reason_desc,
           SUM(sr.sr_return_amt) AS total_return_amt,
           COUNT(*) AS cnt
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND (regexp_like(r.r_reason_desc, '.*size.*')
           OR r.r_reason_desc LIKE '%Wrong size%')
    GROUP BY r.r_reason_id, r.r_reason_desc
  ),
  web_reason AS (
    SELECT r.r_reason_id,
           r.r_reason_desc,
           SUM(wr.wr_return_amt) AS total_return_amt,
           COUNT(*) AS cnt
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND (regexp_like(r.r_reason_desc, '.*size.*')
           OR r.r_reason_desc LIKE '%Wrong size%')
    GROUP BY r.r_reason_id, r.r_reason_desc
  ),
  low_return_reasons AS (
    SELECT r_reason_id
    FROM (
         SELECT r.r_reason_id,
                COALESCE(SUM(sr.sr_return_amt),0) + COALESCE(SUM(wr.wr_return_amt),0) AS tot
         FROM reason r
         LEFT JOIN store_returns sr ON sr.sr_reason_sk = r.r_reason_sk
         LEFT JOIN web_returns wr   ON wr.wr_reason_sk = r.r_reason_sk
         GROUP BY r.r_reason_id
    ) t
    WHERE t.tot < 500
  )
SELECT DISTINCT
       concat(r.r_reason_id, ': ', substr(r.r_reason_desc, 1, 30)) AS reason_summary,
       SUM(coalesce(sr.total_return_amt, 0) + coalesce(wr.total_return_amt, 0)) AS overall_return_amount,
       SUM(coalesce(sr.cnt, 0) + coalesce(wr.cnt, 0)) AS overall_return_count
FROM (
     SELECT r_reason_id, r_reason_desc, total_return_amt, cnt FROM store_reason
     UNION ALL
     SELECT r_reason_id, r_reason_desc, total_return_amt, cnt FROM web_reason
) r
LEFT JOIN store_reason sr ON sr.r_reason_id = r.r_reason_id
LEFT JOIN web_reason   wr ON wr.r_reason_id = r.r_reason_id
WHERE NOT EXISTS (
      SELECT 1 FROM low_return_reasons l WHERE l.r_reason_id = r.r_reason_id
)
GROUP BY r.r_reason_id, r.r_reason_desc
ORDER BY overall_return_amount DESC
LIMIT 100
