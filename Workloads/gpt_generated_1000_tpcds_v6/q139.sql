WITH filtered_returns AS (
   SELECT
       wr.wr_reason_sk,
       wr.wr_return_quantity,
       wr.wr_return_amt,
       wr.wr_net_loss,
       r.r_reason_desc,
       r.r_reason_id,
       regexp_extract(r.r_reason_desc, '^(\\w+)', 1) AS first_word,
       concat(r.r_reason_id, '_', r.r_reason_desc) AS reason_key_desc
   FROM web_returns wr
   JOIN reason r
     ON wr.wr_reason_sk = r.r_reason_sk
   WHERE regexp_like(r.r_reason_desc, '(?i)price|model|warranty')
     AND r.r_reason_id LIKE 'AAAAAAA%'
),
aggregated AS (
   SELECT
       r_reason_desc,
       r_reason_id,
       SUM(wr_net_loss) AS total_net_loss,
       COUNT(*) AS return_cnt,
       AVG(wr_return_amt) AS avg_return_amt
   FROM filtered_returns
   GROUP BY r_reason_desc, r_reason_id
   HAVING SUM(wr_net_loss) > 500
)
SELECT
    r_reason_desc,
    r_reason_id,
    total_net_loss,
    return_cnt,
    avg_return_amt,
    ROW_NUMBER() OVER (ORDER BY total_net_loss DESC) AS loss_rank
FROM aggregated
ORDER BY total_net_loss DESC
LIMIT 100
