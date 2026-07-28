/*
  Goal: Identify high‑value customers with significant net loss from store returns in 2001 (months 1200‑1210),
  focusing on households with mid‑range income, strong buying potential and multiple dependents. The query aggregates
  return metrics per customer, year, and buy‑potential, filters groups by net loss, and compares each group's average
  return amount to the overall average across all returns.
*/
WITH filtered_returns AS (
    SELECT
        sr.sr_customer_sk,
        sr.sr_returned_date_sk,
        sr.sr_return_amt,
        sr.sr_net_loss,
        sr.sr_ticket_number,
        sr.sr_hdemo_sk,
        sr.sr_return_quantity
    FROM store_returns sr
    WHERE sr.sr_return_amt > 100
      AND sr.sr_return_quantity >= 1
      AND sr.sr_returned_date_sk IN (
          SELECT d.d_date_sk
          FROM date_dim d
          WHERE d.d_year = 2001
            AND d.d_month_seq BETWEEN 1200 AND 1210
      )
)
SELECT
    c.c_customer_id,
    d.d_year,
    hd.hd_buy_potential,
    SUM(fr.sr_net_loss)               AS total_net_loss,
    AVG(fr.sr_return_amt)             AS avg_return_amt,
    COUNT(DISTINCT fr.sr_ticket_number) AS distinct_tickets,
    (
        SELECT AVG(sr2.sr_return_amt)
        FROM store_returns sr2
    )                                 AS overall_avg_return_amt
FROM filtered_returns fr
JOIN date_dim d
  ON fr.sr_returned_date_sk = d.d_date_sk
JOIN customer c
  ON fr.sr_customer_sk = c.c_customer_sk
LEFT JOIN household_demographics hd
  ON c.c_current_hdemo_sk = hd.hd_demo_sk
WHERE hd.hd_income_band_sk IN (10, 18)
  AND hd.hd_buy_potential = '1001-5000'
  AND hd.hd_dep_count >= 4
  AND c.c_preferred_cust_flag = 'Y'
  AND c.c_birth_year BETWEEN 1950 AND 1970
GROUP BY
    c.c_customer_id,
    d.d_year,
    hd.hd_buy_potential
HAVING SUM(fr.sr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
