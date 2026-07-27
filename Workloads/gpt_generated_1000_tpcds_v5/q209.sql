/* goal: Identify high‑value customers and their household buying potential who generated return transactions with sizable tax and amount, summarizing distinct ticket counts and return metrics. */
WITH filtered_returns AS (
    SELECT
        sr.sr_customer_sk,
        sr.sr_hdemo_sk,
        sr.sr_ticket_number,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_return_amt_inc_tax,
        sr.sr_net_loss,
        sr.sr_store_credit,
        sr.sr_returned_date_sk
    FROM store_returns sr
    WHERE sr.sr_return_quantity >= 10
      AND sr.sr_return_tax > 5.00
      AND sr.sr_return_amt_inc_tax > 100.00
      AND sr.sr_returned_date_sk BETWEEN 2452000 AND 2453000
)
SELECT
    c.c_customer_id,
    hd.hd_buy_potential,
    COUNT(DISTINCT fr.sr_ticket_number) AS distinct_tickets,
    SUM(fr.sr_return_amt) AS total_return_amount,
    AVG(fr.sr_return_tax) AS avg_return_tax,
    SUM(CASE WHEN hd.hd_vehicle_count > 0 THEN fr.sr_return_quantity ELSE 0 END) AS returns_with_vehicle,
    MIN(fr.sr_return_amt) AS min_return_amount,
    MAX(fr.sr_return_amt) AS max_return_amount
FROM filtered_returns fr
JOIN customer c
    ON fr.sr_customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON fr.sr_hdemo_sk = hd.hd_demo_sk
WHERE c.c_first_shipto_date_sk BETWEEN 2452000 AND 2452500
  AND hd.hd_dep_count IN (2, 6, 9)
  AND hd.hd_buy_potential = '>10000'
  AND c.c_preferred_cust_flag = 'Y'
GROUP BY c.c_customer_id, hd.hd_buy_potential
ORDER BY total_return_amount DESC
LIMIT 100
