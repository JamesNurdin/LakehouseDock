/*
Goal: Identify the most costly return reasons by aggregating net loss from catalog returns and store returns for customers who have a high credit rating and a purchase estimate above 5,000. The query also ensures the customers have at least one high‑value web sale (> $1,000) before including store returns. Results from the two return channels are combined with UNION (distinct) and ordered by total net loss.
*/
WITH high_risk_customers AS (
    SELECT c.c_customer_sk
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating = 'High Risk'
      AND cd.cd_purchase_estimate > 5000
)
SELECT
    r.r_reason_desc AS reason_desc,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS returns_count
FROM catalog_returns cr
JOIN catalog_sales cs
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
JOIN customer c
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
WHERE cr.cr_net_loss > 0
  AND c.c_customer_sk IN (SELECT c_customer_sk FROM high_risk_customers)
GROUP BY r.r_reason_desc

UNION

SELECT
    r.r_reason_desc AS reason_desc,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(*) AS returns_count
FROM store_returns sr
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN customer c
    ON sr.sr_customer_sk = c.c_customer_sk
WHERE sr.sr_net_loss > 0
  AND c.c_customer_sk IN (SELECT c_customer_sk FROM high_risk_customers)
  AND EXISTS (
        SELECT 1
        FROM web_sales ws
        WHERE ws.ws_bill_customer_sk = c.c_customer_sk
          AND ws.ws_net_paid > 1000
    )
GROUP BY r.r_reason_desc

ORDER BY total_net_loss DESC
