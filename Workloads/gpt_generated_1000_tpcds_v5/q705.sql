/*
Goal: Identify product return reasons that are most costly during business hours in a specific county, by first aggregating returns per reason and hour, then computing the average total return amount per reason and filtering to the highest‑impact reasons.
*/
WITH reason_hour_agg AS (
    SELECT
        r.r_reason_desc,
        t.t_hour,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM store_returns AS sr
    JOIN reason AS r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim AS t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer_address AS ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE r.r_reason_desc LIKE '%color%'
      AND ca.ca_county = 'York County'
      AND t.t_hour BETWEEN 9 AND 17
      AND sr.sr_return_amt > 100
    GROUP BY r.r_reason_desc, t.t_hour
)
SELECT
    rha.r_reason_desc,
    AVG(rha.total_return_amt) AS avg_total_return_amt,
    SUM(rha.return_cnt) AS total_returns
FROM reason_hour_agg AS rha
GROUP BY rha.r_reason_desc
HAVING AVG(rha.total_return_amt) > 200
ORDER BY avg_total_return_amt DESC
LIMIT 100
