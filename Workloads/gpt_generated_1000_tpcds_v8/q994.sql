WITH sampled_returns AS (
   SELECT *
   FROM store_returns
   TABLESAMPLE BERNOULLI (10)
),

agg1 AS (
   SELECT
     sr.sr_store_sk,
     r.r_reason_sk,
     r.r_reason_desc,
     COUNT(*) AS return_cnt,
     SUM(sr.sr_return_amt) AS total_return_amt,
     AVG(sr.sr_fee) AS avg_fee
   FROM sampled_returns sr
   JOIN reason r
     ON sr.sr_reason_sk = r.r_reason_sk
   WHERE sr.sr_return_amt > 100
     AND sr.sr_fee < 80
     AND r.r_reason_id = 'AAAAAAAAABAAAAAA'
   GROUP BY sr.sr_store_sk, r.r_reason_sk, r.r_reason_desc
),

agg2 AS (
   SELECT
     sr.sr_store_sk,
     r.r_reason_sk,
     r.r_reason_desc,
     COUNT(*) AS return_cnt,
     SUM(sr.sr_return_amt) AS total_return_amt,
     AVG(sr.sr_fee) AS avg_fee
   FROM sampled_returns sr
   JOIN reason r
     ON sr.sr_reason_sk = r.r_reason_sk
   WHERE sr.sr_return_amt BETWEEN 50 AND 200
     AND sr.sr_store_credit > 10
     AND r.r_reason_desc LIKE '%color%'
   GROUP BY sr.sr_store_sk, r.r_reason_sk, r.r_reason_desc
),

union_agg AS (
   SELECT * FROM agg1
   UNION DISTINCT
   SELECT * FROM agg2
),

high_fee_stores AS (
   SELECT DISTINCT sr_store_sk
   FROM store_returns
   WHERE sr_fee > 70
),

low_fee_stores AS (
   SELECT DISTINCT sr_store_sk
   FROM store_returns
   WHERE sr_fee < 20
),

store_diff AS (
   SELECT sr_store_sk FROM high_fee_stores
   EXCEPT
   SELECT sr_store_sk FROM low_fee_stores
),

reason_word_counts AS (
   SELECT
     r.r_reason_sk,
     w AS word,
     COUNT(*) AS word_occurrences
   FROM reason r
   CROSS JOIN UNNEST(split(r.r_reason_desc, ' ')) AS t(w)
   GROUP BY r.r_reason_sk, w
),

store_specific_reason AS (
   SELECT DISTINCT sr.sr_store_sk
   FROM store_returns sr
   WHERE EXISTS (
       SELECT 1
       FROM reason r
       WHERE r.r_reason_sk = sr.sr_reason_sk
         AND r.r_reason_id = 'AAAAAAAACAAAAAAA'
   )
),

intersected_stores AS (
   SELECT sr_store_sk FROM store_diff
   INTERSECT
   SELECT sr_store_sk FROM store_specific_reason
)

SELECT
   u.sr_store_sk,
   u.r_reason_sk,
   u.r_reason_desc,
   u.return_cnt,
   u.total_return_amt,
   u.avg_fee,
   rwc.word,
   rwc.word_occurrences
FROM union_agg u
JOIN reason_word_counts rwc
  ON u.r_reason_sk = rwc.r_reason_sk
WHERE u.sr_store_sk IN (SELECT sr_store_sk FROM intersected_stores)
ORDER BY u.total_return_amt DESC
LIMIT 100
