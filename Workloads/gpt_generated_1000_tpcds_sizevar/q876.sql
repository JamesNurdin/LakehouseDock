WITH sr AS (
   SELECT
      sr.sr_reason_sk,
      sr.sr_customer_sk,
      sr.sr_return_amt,
      sr.sr_net_loss,
      reason.r_reason_desc,
      CASE WHEN sr.sr_return_amt > 100 THEN 'High' ELSE 'Low' END AS amt_category,
      CONCAT('Store-', CAST(sr.sr_store_sk AS VARCHAR)) AS store_id
   FROM store_returns sr
   TABLESAMPLE BERNOULLI (10)   -- sample 10 % of rows
   JOIN reason ON sr.sr_reason_sk = reason.r_reason_sk
   WHERE regexp_like(reason.r_reason_desc, 'size')
),
wr AS (
   SELECT
      wr.wr_reason_sk,
      wr.wr_refunded_customer_sk,
      wr.wr_return_amt,
      wr.wr_net_loss,
      reason.r_reason_desc,
      CASE WHEN wr.wr_return_amt > 100 THEN 'High' ELSE 'Low' END AS amt_category,
      CONCAT('Web-', CAST(wr.wr_web_page_sk AS VARCHAR)) AS web_page_id
   FROM web_returns wr
   TABLESAMPLE BERNOULLI (10)   -- sample 10 % of rows
   JOIN reason ON wr.wr_reason_sk = reason.r_reason_sk
   WHERE reason.r_reason_id LIKE 'AAAAAAAA%AA'
)
SELECT
   COALESCE(sr.sr_reason_sk, wr.wr_reason_sk) AS reason_sk,
   COALESCE(sr.r_reason_desc, wr.r_reason_desc) AS reason_desc,
   COUNT(DISTINCT sr.sr_customer_sk)                AS distinct_store_customers,
   COUNT(DISTINCT wr.wr_refunded_customer_sk)      AS distinct_web_customers,
   SUM(DISTINCT sr.sr_return_amt)                  AS distinct_store_return_amt,
   SUM(DISTINCT wr.wr_return_amt)                  AS distinct_web_return_amt,
   SUM(CASE WHEN sr.amt_category = 'High' THEN sr.sr_net_loss ELSE 0 END) AS store_high_net_loss,
   SUM(CASE WHEN wr.amt_category = 'High' THEN wr.wr_net_loss ELSE 0 END) AS web_high_net_loss
FROM sr
FULL OUTER JOIN wr
   ON sr.sr_reason_sk = wr.wr_reason_sk
GROUP BY
   COALESCE(sr.sr_reason_sk, wr.wr_reason_sk),
   COALESCE(sr.r_reason_desc, wr.r_reason_desc)
ORDER BY reason_sk
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
