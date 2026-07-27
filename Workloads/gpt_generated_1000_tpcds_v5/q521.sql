WITH per_demo AS (
   SELECT
       hd.hd_demo_sk,
       hd.hd_income_band_sk,
       hd.hd_buy_potential,
       SUM(sr.sr_net_loss) AS total_net_loss,
       AVG(sr.sr_return_amt_inc_tax) AS avg_return_amt_inc_tax,
       COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets
   FROM store_returns sr
   INNER JOIN customer c
       ON sr.sr_customer_sk = c.c_customer_sk
   LEFT JOIN household_demographics hd
       ON sr.sr_hdemo_sk = hd.hd_demo_sk
   WHERE c.c_salutation IN ('Mr.', 'Mrs.', 'Dr.')
     AND c.c_first_shipto_date_sk BETWEEN 2449000 AND 2452000
     AND hd.hd_income_band_sk IN (13, 14, 17, 20)
     AND hd.hd_buy_potential = '1001-5000'
     AND sr.sr_reason_sk NOT IN (6, 34)
   GROUP BY hd.hd_demo_sk, hd.hd_income_band_sk, hd.hd_buy_potential
)
SELECT
    hd_demo_sk,
    hd_income_band_sk,
    COALESCE(hd_buy_potential, 'Unknown') AS buy_potential,
    total_net_loss,
    avg_return_amt_inc_tax,
    distinct_tickets,
    total_net_loss / NULLIF(distinct_tickets, 0) AS loss_per_ticket
FROM per_demo
WHERE total_net_loss > 1000
  AND avg_return_amt_inc_tax < 2000
  AND distinct_tickets >= 5
ORDER BY total_net_loss DESC
LIMIT 100
