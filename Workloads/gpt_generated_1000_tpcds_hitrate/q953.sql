WITH market_stores AS (
    SELECT s_store_sk,
           s_store_name,
           s_state
    FROM store
    WHERE s_store_name LIKE '%Market%'
      AND REGEXP_LIKE(s_store_name, 'Market')
)
SELECT
    ms.s_store_name,
    ms.s_state,
    t.t_hour,
    MIN(CONCAT(ms.s_store_name, '_', ms.s_state))               AS store_label,
    MIN(REGEXP_EXTRACT(ms.s_store_name, '(Market)', 1))          AS market_word,
    SUM(ss.ss_net_profit)                                        AS total_net_profit,
    (SELECT MAX(ib_upper_bound) FROM income_band)               AS max_income_upper,
    ROW_NUMBER() OVER (ORDER BY SUM(ss.ss_net_profit) DESC)      AS rn
FROM store_sales ss
JOIN market_stores ms
    ON ss.ss_store_sk = ms.s_store_sk
JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
WHERE r.r_reason_desc LIKE '%damaged%'
  AND EXISTS (SELECT 1 FROM catalog_page cp WHERE cp.cp_type LIKE 'A%')
  AND ss.ss_store_sk IN (
        SELECT s_store_sk FROM store WHERE s_store_name LIKE '%Market%'
      )
GROUP BY GROUPING SETS (
    (ms.s_store_name, ms.s_state, t.t_hour),
    (ms.s_store_name, ms.s_state),
    ()
)
ORDER BY total_net_profit DESC
OFFSET 0
LIMIT 100
