/*
  Goal: Summarize return performance by store and hour of day for California male customers during business hours, comparing store and web return amounts. The query joins all seven TPC‑DS tables, applies selective filters, uses a LEFT OUTER JOIN to bring in web returns (preserving stores with no web returns), handles NULLs with COALESCE, includes a CASE expression, a DISTINCT count, and several aggregates.
*/
SELECT
    s.s_store_id,
    td.t_hour,
    CASE WHEN s.s_state = 'CA' THEN 'CA Store' ELSE 'Other Store' END AS store_region,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_store_tickets,
    SUM(sr.sr_return_amt) AS total_store_return_amt,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_web_return_amt,
    COUNT(*) AS total_return_rows,
    AVG(sr.sr_return_amt) AS avg_store_return_amt,
    MIN(sr.sr_return_amt) AS min_store_return_amt,
    MAX(sr.sr_return_amt) AS max_store_return_amt
FROM store_returns sr
JOIN time_dim td
  ON sr.sr_return_time_sk = td.t_time_sk
JOIN customer_demographics cd
  ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca
  ON sr.sr_addr_sk = ca.ca_address_sk
JOIN store s
  ON sr.sr_store_sk = s.s_store_sk
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN web_returns wr
  ON wr.wr_returned_time_sk = td.t_time_sk
  AND wr.wr_reason_sk = r.r_reason_sk
  AND wr.wr_refunded_addr_sk = ca.ca_address_sk
  AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
WHERE ca.ca_state = 'CA'
  AND cd.cd_gender = 'M'
  AND td.t_hour BETWEEN 9 AND 17
GROUP BY
    s.s_store_id,
    td.t_hour,
    CASE WHEN s.s_state = 'CA' THEN 'CA Store' ELSE 'Other Store' END
ORDER BY total_store_return_amt DESC
LIMIT 100
