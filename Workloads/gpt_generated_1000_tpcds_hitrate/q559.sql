WITH sr_agg AS (
    SELECT
        sr_customer_sk,
        sr_hdemo_sk,
        sr_addr_sk,
        SUM(sr_return_amt)                         AS total_return_amt,
        AVG(sr_return_amt_inc_tax)                 AS avg_return_inc_tax,
        COUNT(*)                                   AS return_cnt,
        MIN(sr_return_ship_cost)                   AS min_ship_cost,
        MAX(sr_store_credit)                       AS max_store_credit
    FROM store_returns
    WHERE sr_return_ship_cost > 30
      AND sr_return_amt > 20
      AND sr_return_quantity >= 1
    GROUP BY sr_customer_sk, sr_hdemo_sk, sr_addr_sk
)
SELECT
    ca.ca_state,
    hd.hd_buy_potential,
    c.c_preferred_cust_flag,
    SUM(sr.total_return_amt)      AS sum_total_return_amt,
    AVG(sr.avg_return_inc_tax)    AS avg_return_inc_tax,
    SUM(sr.return_cnt)            AS total_returns,
    MIN(sr.min_ship_cost)         AS min_ship_cost,
    MAX(sr.max_store_credit)      AS max_store_credit
FROM sr_agg AS sr
JOIN customer AS c
  ON sr.sr_customer_sk = c.c_customer_sk
JOIN household_demographics AS hd
  ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN customer_address AS ca
  ON sr.sr_addr_sk = ca.ca_address_sk
WHERE c.c_birth_year BETWEEN 1960 AND 1975
  AND c.c_preferred_cust_flag = 'Y'
  AND c.c_login LIKE '%mail%'
  AND hd.hd_vehicle_count >= 2
  AND hd.hd_buy_potential = '1001-5000'
  AND ca.ca_state = 'CA'
  AND sr.sr_customer_sk IN (
        SELECT c2.c_customer_sk
        FROM customer AS c2
        WHERE c2.c_birth_country = 'United States'
  )
  AND sr.sr_customer_sk IN (
        (SELECT c3.c_customer_sk FROM customer AS c3 WHERE c3.c_preferred_cust_flag = 'Y')
        EXCEPT
        (SELECT c4.c_customer_sk FROM customer AS c4 WHERE c4.c_birth_year < 1970)
  )
  AND EXISTS (
        SELECT 1
        FROM customer_address AS ca2
        WHERE ca2.ca_address_sk = sr.sr_addr_sk
          AND ca2.ca_city LIKE 'San%'
  )
GROUP BY CUBE (ca.ca_state, hd.hd_buy_potential, c.c_preferred_cust_flag)
ORDER BY sum_total_return_amt DESC
LIMIT 100
