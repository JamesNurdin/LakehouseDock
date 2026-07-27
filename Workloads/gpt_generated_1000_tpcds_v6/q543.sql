WITH filtered_items AS (
    SELECT i_item_sk,
           i_product_name,
           i_item_desc,
           regexp_extract(i_item_desc, '(\\w+)', 1) AS first_word
    FROM item
    WHERE regexp_like(i_item_desc, '^\\w{4,}\\s')
)
SELECT
    d.d_year,
    d.d_month_seq AS month_seq,
    s.s_store_name,
    CONCAT(s.s_store_name, ' - ', SUBSTRING(ca.ca_city, 1, 3)) AS store_city_code,
    COUNT(sr.sr_ticket_number) AS total_returns,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(sr.sr_return_amt) AS avg_return_amount,
    (
        SELECT AVG(sr2.sr_return_amt)
        FROM store_returns sr2
        JOIN date_dim d2 ON sr2.sr_returned_date_sk = d2.d_date_sk
        WHERE d2.d_year = d.d_year
          AND d2.d_month_seq = d.d_month_seq
    ) AS avg_monthly_return_amount,
    SUM(CASE WHEN regexp_like(ca.ca_city, '.*County$') THEN 1 ELSE 0 END) AS returns_in_county_cities
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN filtered_items fi ON sr.sr_item_sk = fi.i_item_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
WHERE d.d_year = 2001
  AND s.s_state = 'CA'
  AND ca.ca_city LIKE '%County'
GROUP BY d.d_year, d.d_month_seq, s.s_store_name, CONCAT(s.s_store_name, ' - ', SUBSTRING(ca.ca_city, 1, 3))
ORDER BY total_return_amount DESC
LIMIT 10
