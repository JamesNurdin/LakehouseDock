WITH avg_return_amt AS (
    SELECT avg(wr_return_amt) AS avg_amt
    FROM web_returns
)
SELECT
    wr.wr_returning_customer_sk AS customer_sk,
    ca_returning.ca_city AS city,
    hd_returning.hd_income_band_sk AS income_band,
    wr.wr_return_amt,
    'Returning' AS role
FROM web_returns wr
JOIN customer_address ca_returning
    ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
JOIN household_demographics hd_returning
    ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
WHERE ca_returning.ca_city = 'Oakdale'
  AND wr.wr_return_amt > (SELECT avg_amt FROM avg_return_amt)

UNION ALL

SELECT
    wr.wr_refunded_customer_sk AS customer_sk,
    ca_refunded.ca_city AS city,
    hd_refunded.hd_income_band_sk AS income_band,
    wr.wr_return_amt,
    'Refunded' AS role
FROM web_returns wr
JOIN customer_address ca_refunded
    ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN household_demographics hd_refunded
    ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
WHERE ca_refunded.ca_city = 'Pleasant Valley'
  AND EXISTS (
        SELECT 1
        FROM household_demographics hd2
        WHERE hd2.hd_demo_sk = wr.wr_refunded_hdemo_sk
          AND hd2.hd_vehicle_count >= 2
    )
