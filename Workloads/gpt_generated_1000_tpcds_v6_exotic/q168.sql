/*
  Goal: Identify high‑income customers who have incurred significant net loss from store and web returns, grouped by customer and return reason, and only include customers with at least one large catalog sale.
*/
WITH high_income_customers AS (
    SELECT c.c_customer_sk
    FROM customer c
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound > 80000
)
SELECT
    cust.c_customer_id,
    r.r_reason_desc,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count
FROM store_returns sr
JOIN customer cust ON sr.sr_customer_sk = cust.c_customer_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN high_income_customers hic ON cust.c_customer_sk = hic.c_customer_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_sales cs
    WHERE cs.cs_bill_customer_sk = cust.c_customer_sk
      AND cs.cs_net_paid > 1000
)
GROUP BY cust.c_customer_id, r.r_reason_desc
HAVING SUM(sr.sr_net_loss) > 1000

UNION ALL

SELECT
    cust.c_customer_id,
    r.r_reason_desc,
    SUM(wr.wr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count
FROM web_returns wr
JOIN customer cust ON wr.wr_refunded_customer_sk = cust.c_customer_sk
JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
JOIN high_income_customers hic ON cust.c_customer_sk = hic.c_customer_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_sales cs
    WHERE cs.cs_ship_customer_sk = cust.c_customer_sk
      AND cs.cs_net_paid > 1000
)
GROUP BY cust.c_customer_id, r.r_reason_desc
HAVING SUM(wr.wr_net_loss) > 1000

ORDER BY total_net_loss DESC
