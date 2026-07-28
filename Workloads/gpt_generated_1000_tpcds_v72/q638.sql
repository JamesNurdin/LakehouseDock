/*
Goal: Summarize catalog return losses by reason description that mentions "size", and by customer address details, for returns in the year 2001. The query demonstrates regex filtering, LIKE pattern matching, substring extraction, and concatenation, while joining store_returns with date_dim, reason, and customer_address. Results are ordered by total net loss and limited to the top 100 rows.
*/
SELECT
    r.r_reason_desc,
    ca.ca_state,
    substring(ca.ca_zip, 1, 3) AS zip_prefix,
    concat(ca.ca_city, ', ', ca.ca_state) AS city_state,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  AND regexp_like(r.r_reason_desc, '(?i)size')
  AND ca.ca_zip LIKE '9%'
GROUP BY
    r.r_reason_desc,
    ca.ca_state,
    substring(ca.ca_zip, 1, 3),
    concat(ca.ca_city, ', ', ca.ca_state)
ORDER BY total_net_loss DESC
LIMIT 100
