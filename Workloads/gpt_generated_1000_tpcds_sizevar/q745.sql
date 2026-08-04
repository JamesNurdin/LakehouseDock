WITH
  promo_sample AS (
    SELECT *
    FROM promotion
    TABLESAMPLE BERNOULLI (10)
    WHERE regexp_like(p_promo_name, '(?i)discount')
  ),
  full_promo_reason AS (
    SELECT p.p_promo_sk,
           p.p_promo_name,
           r.r_reason_sk,
           r.r_reason_desc
    FROM promotion p
    FULL OUTER JOIN reason r
      ON TRUE
  ),
  select1 AS (
    SELECT
      fp.p_promo_name AS promo_name,
      fp.r_reason_desc AS reason_desc,
      SUM(sr.sr_return_amt) AS return_amt,
      0.0 AS net_profit,
      COUNT(DISTINCT sr.sr_ticket_number) AS txn_count
    FROM full_promo_reason fp
    LEFT JOIN store_returns sr
      ON sr.sr_reason_sk = fp.r_reason_sk
    LEFT JOIN store_sales ss
      ON ss.ss_ticket_number = sr.sr_ticket_number
     AND ss.ss_item_sk = sr.sr_item_sk
    WHERE fp.p_promo_name LIKE CONCAT('%', 'Discount', '%')
      AND regexp_like(fp.r_reason_desc, '^Wrong')
    GROUP BY fp.p_promo_name, fp.r_reason_desc
  ),
  select2 AS (
    SELECT
      p.p_promo_name AS promo_name,
      NULL AS reason_desc,
      0.0 AS return_amt,
      SUM(ss.ss_net_profit) AS net_profit,
      COUNT(DISTINCT ss.ss_ticket_number) AS txn_count
    FROM store_sales ss
    JOIN promo_sample p
      ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_promo_id = (
            SELECT p_promo_id
            FROM promotion
            WHERE p_promo_sk = 1000
          )
    GROUP BY p.p_promo_name
  ),
  union_all AS (
    SELECT * FROM select1
    UNION
    SELECT * FROM select2
  )
SELECT
  promo_name,
  reason_desc,
  CONCAT(promo_name, ': ', COALESCE(reason_desc, 'No Reason')) AS promo_reason_label,
  SUM(return_amt) AS total_return_amt,
  SUM(net_profit) AS total_net_profit,
  SUM(txn_count) AS total_transactions
FROM union_all
GROUP BY
  promo_name,
  reason_desc,
  CONCAT(promo_name, ': ', COALESCE(reason_desc, 'No Reason'))
ORDER BY total_net_profit DESC
LIMIT 100
