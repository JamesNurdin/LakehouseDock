WITH filtered_stores AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_zip,
        s.s_number_employees,
        CONCAT(s.s_store_name, ' - ', s.s_state) AS store_label,
        SUBSTR(s.s_city, 1, 3) AS city_prefix,
        regexp_extract(s.s_zip, '(\\d{2})', 1) AS zip_prefix
    FROM store s
    WHERE regexp_like(s.s_store_name, '^Store [A-Z][0-9]{2}$')
      AND s.s_state LIKE 'C%'
)
SELECT
    fs.store_label,
    fs.city_prefix,
    fs.zip_prefix,
    d.d_year,
    COUNT(*) AS return_count,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_return_amt_inc_tax) AS avg_return_amount_inc_tax
FROM filtered_stores fs
JOIN store_returns sr
    ON sr.sr_store_sk = fs.s_store_sk
JOIN date_dim d
    ON sr.sr_returned_date_sk = d.d_date_sk
JOIN time_dim t
    ON sr.sr_return_time_sk = t.t_time_sk
JOIN customer_address ca
    ON sr.sr_addr_sk = ca.ca_address_sk
WHERE t.t_sub_shift = 'evening'
  AND ca.ca_city LIKE '%ville%'
GROUP BY
    fs.store_label,
    fs.city_prefix,
    fs.zip_prefix,
    d.d_year
ORDER BY total_net_loss DESC
LIMIT 100
