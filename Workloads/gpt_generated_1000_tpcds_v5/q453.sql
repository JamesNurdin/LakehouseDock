WITH filtered_returns AS (
    SELECT
        sr.sr_return_amt,
        sr.sr_fee,
        sr.sr_reversed_charge,
        sr.sr_return_quantity,
        sr.sr_hdemo_sk,
        sr.sr_addr_sk
    FROM store_returns sr
    WHERE sr.sr_fee > 10
      AND sr.sr_reversed_charge < 500
      AND sr.sr_return_quantity BETWEEN 1 AND 10
      AND sr.sr_return_amt > 0
      AND sr.sr_return_tax >= 0
      AND sr.sr_return_ship_cost <= 50
)
SELECT
    (SELECT ca.ca_city
     FROM customer_address ca
     WHERE ca.ca_address_sk = fr.sr_addr_sk) AS city,
    hd.hd_buy_potential,
    SUM(fr.sr_return_amt) AS total_return_amount,
    AVG(fr.sr_fee) AS avg_fee,
    COUNT(*) AS return_count,
    MIN(fr.sr_return_quantity) AS min_qty,
    MAX(fr.sr_return_quantity) AS max_qty
FROM filtered_returns fr
JOIN household_demographics hd
  ON fr.sr_hdemo_sk = hd.hd_demo_sk
WHERE hd.hd_dep_count >= 3
  AND hd.hd_income_band_sk IN (8, 11, 12)
  AND EXISTS (
        SELECT 1
        FROM customer_address ca
        WHERE ca.ca_address_sk = fr.sr_addr_sk
          AND ca.ca_country = 'United States'
          AND ca.ca_state = 'CA'
          AND ca.ca_suite_number LIKE 'Suite %'
          AND ca.ca_zip BETWEEN '90001' AND '90099'
      )
GROUP BY
    (SELECT ca.ca_city
     FROM customer_address ca
     WHERE ca.ca_address_sk = fr.sr_addr_sk),
    hd.hd_buy_potential
ORDER BY total_return_amount DESC
LIMIT 100
