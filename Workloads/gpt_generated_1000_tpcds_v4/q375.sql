WITH sales_enriched AS (
    SELECT
        ss.ss_net_profit,
        ss.ss_net_paid,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ca.ca_city,
        ca.ca_state,
        CAST(regexp_extract(ca.ca_street_number, '([0-9]+)', 1) AS integer) AS street_num_int,
        concat(ca.ca_city, ', ', ca.ca_state) AS location
    FROM store_sales ss
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ca.ca_city LIKE '%County'
      AND regexp_like(ca.ca_street_number, '^[0-9]+$')
)
SELECT
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    COUNT(*) AS sales_cnt,
    SUM(ss_net_profit) AS total_profit,
    AVG(ss_net_paid) AS avg_paid,
    MIN(street_num_int) AS min_street_num,
    MAX(street_num_int) AS max_street_num
FROM sales_enriched
GROUP BY ib_income_band_sk, ib_lower_bound, ib_upper_bound
ORDER BY total_profit DESC
LIMIT 100
