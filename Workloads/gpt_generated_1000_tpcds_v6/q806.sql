WITH customer_income AS (
    SELECT c.c_customer_sk,
           ib.ib_lower_bound,
           ib.ib_upper_bound
    FROM customer c
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT
    ci.ib_lower_bound,
    ci.ib_upper_bound,
    'High Ship Cost' AS segment,
    SUM(sr.sr_return_amt) AS total_return_amount
FROM store_returns sr
JOIN customer_income ci ON sr.sr_customer_sk = ci.c_customer_sk
WHERE sr.sr_return_ship_cost > 100
GROUP BY ci.ib_lower_bound, ci.ib_upper_bound, 'High Ship Cost'

UNION ALL

SELECT
    ci.ib_lower_bound,
    ci.ib_upper_bound,
    'Low Tax' AS segment,
    SUM(sr.sr_return_amt) AS total_return_amount
FROM store_returns sr
JOIN customer_income ci ON sr.sr_customer_sk = ci.c_customer_sk
WHERE sr.sr_return_tax < 5
GROUP BY ci.ib_lower_bound, ci.ib_upper_bound, 'Low Tax'

ORDER BY total_return_amount DESC
LIMIT 100
