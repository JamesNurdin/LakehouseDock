WITH filtered_returns AS (
   SELECT
       sr_return_amt,
       sr_store_credit,
       sr_store_sk,
       sr_reason_sk,
       CASE WHEN sr_return_amt > 1000 THEN 'high' ELSE 'low' END AS amt_category
   FROM store_returns
   WHERE sr_return_amt > 500
     AND sr_store_credit < 300
     AND sr_store_sk IN (
         SELECT sr_store_sk FROM store_returns WHERE sr_return_quantity > 1
     )
),
reason_agg AS (
   SELECT
       r.r_reason_sk,
       r.r_reason_desc,
       COUNT(*) AS cnt_returns,
       SUM(fr.sr_return_amt) AS total_return_amt,
       SUM(fr.sr_store_credit) AS total_store_credit,
       SUM(CASE WHEN fr.amt_category = 'high' THEN 1 ELSE 0 END) AS high_amt_cnt
   FROM filtered_returns fr
   JOIN reason r ON fr.sr_reason_sk = r.r_reason_sk
   GROUP BY ROLLUP (r.r_reason_sk, r.r_reason_desc)
),
store_set_a AS (
   SELECT DISTINCT sr_store_sk FROM store_returns WHERE sr_return_amt BETWEEN 800 AND 2000
),
store_set_b AS (
   SELECT DISTINCT sr_store_sk FROM store_returns WHERE sr_store_credit > 200
),
store_set_c AS (
   SELECT DISTINCT sr_store_sk FROM store_returns WHERE sr_return_quantity = 1
),
except_set AS (
   SELECT sr_store_sk FROM store_set_a
   EXCEPT
   SELECT sr_store_sk FROM store_set_b
),
intersect_set AS (
   SELECT sr_store_sk FROM except_set
   INTERSECT
   SELECT sr_store_sk FROM store_set_c
),
final AS (
   SELECT
       ra.r_reason_sk,
       ra.r_reason_desc,
       ra.cnt_returns,
       ra.total_return_amt,
       ra.total_store_credit,
       ra.high_amt_cnt,
       (
           SELECT SUM(sr2.sr_return_tax)
           FROM store_returns sr2
           WHERE sr2.sr_reason_sk = ra.r_reason_sk
             AND sr2.sr_store_sk IN (SELECT sr_store_sk FROM intersect_set)
       ) AS tax_sum_for_intersect_stores
   FROM reason_agg ra
   WHERE ra.r_reason_sk IS NOT NULL
)
SELECT *
FROM final
ORDER BY total_return_amt DESC NULLS LAST, r_reason_desc
LIMIT 100
