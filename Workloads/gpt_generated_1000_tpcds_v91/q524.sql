SELECT
    d.d_year AS year,
    d.d_moy AS month,
    r.r_reason_desc AS reason,
    ib.ib_lower_bound AS income_lower,
    ib.ib_upper_bound AS income_upper,
    hd.hd_buy_potential AS buy_potential,
    COUNT(*) AS return_count,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(sr.sr_return_amt) AS avg_return_amount,
    MIN(sr.sr_return_amt) AS min_return_amount,
    MAX(sr.sr_return_amt) AS max_return_amount
FROM store_returns sr
JOIN date_dim d
  ON sr.sr_returned_date_sk = d.d_date_sk
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN customer_address ca
  ON sr.sr_addr_sk = ca.ca_address_sk
JOIN household_demographics hd
  ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer c
  ON sr.sr_customer_sk = c.c_customer_sk
WHERE d.d_date >= DATE '2001-01-01'
  AND d.d_date <= DATE '2001-03-31'
  AND r.r_reason_desc = 'Found a better price in a store'
  AND ib.ib_lower_bound >= 30000
  AND ib.ib_upper_bound <= 50000
  AND hd.hd_buy_potential = '>10000'
  AND sr.sr_return_amt > 100.00
GROUP BY
    d.d_year,
    d.d_moy,
    r.r_reason_desc,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd.hd_buy_potential
ORDER BY total_return_amount DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
