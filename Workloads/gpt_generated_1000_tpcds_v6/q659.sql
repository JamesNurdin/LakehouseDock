WITH per_customer_return AS (
    SELECT
        ca.ca_county AS county,
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper,
        cd.cd_gender AS gender,
        c.c_salutation AS salutation,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt,
        AVG(sr.sr_return_amt) AS avg_return_amt,
        SUM(CASE WHEN sr.sr_return_amt > 100 THEN sr.sr_return_amt ELSE 0 END) AS high_return_sum
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ca.ca_county = 'Maricopa County'
      AND ib.ib_lower_bound >= 50000
      AND cd.cd_gender = 'F'
      AND c.c_salutation = 'Ms.'
      AND sr.sr_return_amt > 0
    GROUP BY ca.ca_county, ib.ib_lower_bound, ib.ib_upper_bound, cd.cd_gender, c.c_salutation
)
SELECT
    county,
    income_lower,
    income_upper,
    gender,
    salutation,
    total_return_amt,
    return_cnt,
    avg_return_amt,
    high_return_sum,
    CASE
        WHEN total_return_amt > 10000 THEN 'High'
        WHEN total_return_amt BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS return_category
FROM per_customer_return
WHERE return_cnt >= 5
ORDER BY total_return_amt DESC
LIMIT 100
