WITH purchases AS (
    SELECT c.c_customer_id AS customer_id,
           SUM(cs.cs_net_paid_inc_tax) AS amount
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cs.cs_net_profit > 5000
      AND ib.ib_upper_bound >= 100000
    GROUP BY c.c_customer_id
),
returns AS (
    SELECT c.c_customer_id AS customer_id,
           -SUM(sr.sr_net_loss) AS amount
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE sr.sr_net_loss > 2000
      AND ib.ib_upper_bound >= 100000
    GROUP BY c.c_customer_id
)
SELECT u.customer_id,
       SUM(u.amount) AS net_amount
FROM (
    SELECT DISTINCT customer_id, amount FROM purchases
    UNION ALL
    SELECT DISTINCT customer_id, amount FROM returns
) u
GROUP BY u.customer_id
ORDER BY net_amount DESC
LIMIT 100
