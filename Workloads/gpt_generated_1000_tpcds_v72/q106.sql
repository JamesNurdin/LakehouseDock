WITH filtered_returns AS (
    SELECT 
        wr.wr_return_amt,
        wr.wr_fee,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        r.r_reason_desc
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE regexp_like(ca.ca_zip, '^9[0-5][0-9]{3}$')
      AND ca.ca_city LIKE 'A%'
)
SELECT 
    regexp_extract(r_reason_desc, '(\\w+)') AS reason_keyword,
    concat(ca_city, ', ', ca_state) AS city_state,
    sum(wr_return_amt) AS total_return_amt,
    avg(wr_fee) AS avg_fee,
    count(*) AS returns_count
FROM filtered_returns
GROUP BY 
    regexp_extract(r_reason_desc, '(\\w+)'),
    concat(ca_city, ', ', ca_state)
ORDER BY total_return_amt DESC
LIMIT 100
