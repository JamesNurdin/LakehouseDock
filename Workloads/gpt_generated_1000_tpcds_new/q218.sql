WITH sampled_returns AS (
    SELECT *
    FROM web_returns TABLESAMPLE BERNOULLI (10)
),
intersected_addrs AS (
    SELECT ca_address_sk
    FROM customer_address
    WHERE regexp_like(ca_city, 'County$')
    INTERSECT
    SELECT ca_address_sk
    FROM customer_address
    WHERE ca_country = 'United States' AND ca_state LIKE 'C%'
)
SELECT
    a.ca_county,
    CONCAT(a.ca_city, ', ', a.ca_state) AS location,
    regexp_extract(a.ca_zip, '(\\d{3})', 1) AS zip_prefix,
    SUM(r.wr_net_loss) AS total_net_loss,
    COUNT(r.wr_order_number) AS returns_cnt
FROM sampled_returns r
JOIN customer_address a
    ON r.wr_refunded_addr_sk = a.ca_address_sk
WHERE a.ca_address_sk IN (SELECT ca_address_sk FROM intersected_addrs)
  AND a.ca_street_type LIKE 'St%'
GROUP BY a.ca_county, a.ca_city, a.ca_state, a.ca_zip
HAVING SUM(r.wr_net_loss) > 0

UNION DISTINCT

SELECT
    a.ca_state,
    CONCAT(a.ca_city, ', ', a.ca_state) AS location,
    regexp_extract(a.ca_zip, '(\\d{3})', 1) AS zip_prefix,
    SUM(r.wr_net_loss) AS total_net_loss,
    COUNT(r.wr_order_number) AS returns_cnt
FROM sampled_returns r
JOIN customer_address a
    ON r.wr_returning_addr_sk = a.ca_address_sk
WHERE a.ca_address_sk IN (SELECT ca_address_sk FROM intersected_addrs)
  AND regexp_like(a.ca_street_type, '^(Blvd|Rd)$')
GROUP BY a.ca_state, a.ca_city, a.ca_zip
HAVING COUNT(r.wr_order_number) > 5

ORDER BY total_net_loss DESC
LIMIT 100
