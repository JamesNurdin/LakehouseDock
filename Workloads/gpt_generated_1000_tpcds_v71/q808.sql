WITH filtered_returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_cdemo_sk,
        sr.sr_hdemo_sk,
        sr.sr_addr_sk,
        sr.sr_return_amt,
        sr.sr_refunded_cash,
        sr.sr_return_quantity,
        sr.sr_ticket_number
    FROM store_returns sr
    WHERE sr.sr_return_amt > 100
      AND sr.sr_return_quantity BETWEEN 1 AND 5
      AND sr.sr_return_time_sk BETWEEN 30000 AND 60000
)
SELECT
    s.s_store_name,
    s.s_state,
    cd.cd_gender,
    cd.cd_education_status,
    ca.ca_city,
    SUM(fr.sr_return_amt) AS total_return_amount,
    AVG(fr.sr_refunded_cash) AS avg_refunded_cash,
    COUNT(fr.sr_ticket_number) AS return_count,
    MIN(fr.sr_return_quantity) AS min_qty,
    MAX(fr.sr_return_quantity) AS max_qty
FROM filtered_returns fr
JOIN store s
  ON fr.sr_store_sk = s.s_store_sk
JOIN customer_demographics cd
  ON fr.sr_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON fr.sr_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
  ON fr.sr_addr_sk = ca.ca_address_sk
WHERE s.s_state = 'CA'
  AND s.s_country = 'United States'
  AND cd.cd_gender = 'M'
  AND cd.cd_education_status = 'Advanced Degree'
  AND ca.ca_state = 'CA'
  AND hd.hd_income_band_sk = 5
GROUP BY s.s_store_name, s.s_state, cd.cd_gender, cd.cd_education_status, ca.ca_city
ORDER BY total_return_amount DESC
LIMIT 100
