WITH sr_details AS (
    SELECT
        sr.sr_return_amt,
        sr.sr_return_quantity,
        i.i_category,
        i.i_units,
        ca.ca_city,
        regexp_extract(ca.ca_suite_number, '(\\d+)', 1) AS suite_number,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE i.i_units LIKE '%e%'
      AND regexp_like(ca.ca_city, '^A')
)
SELECT
    i_category,
    suite_number,
    ib_lower_bound,
    ib_upper_bound,
    COUNT(*) AS return_cnt,
    SUM(sr_return_amt) AS total_return_amt,
    AVG(sr_return_amt) AS avg_return_amt,
    CASE WHEN SUM(sr_return_amt) > 5000 THEN 'High' ELSE 'Low' END AS return_level,
    CONCAT('Suite ', suite_number) AS suite_label
FROM sr_details
GROUP BY
    i_category,
    suite_number,
    ib_lower_bound,
    ib_upper_bound
ORDER BY total_return_amt DESC
LIMIT 100
