WITH avg_return AS (
    SELECT AVG(sr3.sr_return_amt) AS avg_amt
    FROM store_returns sr3
)
SELECT
    ca.ca_county,
    r.r_reason_desc,
    SUM(sr.sr_return_amt) AS total_return_amt,
    COUNT(*) AS return_cnt,
    (SELECT avg_amt FROM avg_return) AS avg_return_amt
FROM store_returns sr
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
WHERE r.r_reason_desc = 'Did not get it on time'
  AND t.t_shift = 'Morning'
  AND EXISTS (
        SELECT 1
        FROM customer_address ca2
        WHERE ca2.ca_city = ca.ca_city
          AND ca2.ca_county = 'Bledsoe County'
    )
GROUP BY ca.ca_county, r.r_reason_desc

UNION ALL

SELECT
    ca.ca_county,
    r.r_reason_desc,
    SUM(sr.sr_return_amt) AS total_return_amt,
    COUNT(*) AS return_cnt,
    (SELECT avg_amt FROM avg_return) AS avg_return_amt
FROM store_returns sr
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
WHERE r.r_reason_desc = 'Gift exchange'
  AND t.t_shift = 'Evening'
  AND ca.ca_state = 'CA'
GROUP BY ca.ca_county, r.r_reason_desc

ORDER BY total_return_amt DESC, return_cnt DESC
LIMIT 100
