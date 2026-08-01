WITH filtered_returns AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_item_sk,
        sr.sr_addr_sk,
        sr.sr_store_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        i.i_category,
        i.i_formulation,
        ca.ca_location_type,
        d.d_year
    FROM store_returns sr
    JOIN date_dim d
      ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i
      ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_address ca
      ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2000
      AND ca.ca_location_type LIKE 'apartment%'
      AND regexp_like(i.i_formulation, '[0-9]{3,}')
)
SELECT
    s.s_store_name,
    fr.i_category,
    COUNT(*) AS return_cnt,
    SUM(fr.sr_return_quantity) AS total_quantity,
    SUM(fr.sr_return_amt) AS total_amount,
    SUM(CASE WHEN regexp_like(fr.i_formulation, '^\\d') THEN 1 ELSE 0 END) AS formulation_starts_digit_cnt,
    MIN(regexp_extract(fr.i_formulation, '([A-Za-z]+)')) AS sample_alpha_formulation,
    CONCAT('Store: ', s.s_store_name, ' Cat: ', fr.i_category) AS label
FROM filtered_returns fr
JOIN store s
  ON fr.sr_store_sk = s.s_store_sk
GROUP BY s.s_store_name, fr.i_category
ORDER BY total_amount DESC
LIMIT 100
