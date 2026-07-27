WITH customer_returns AS (
    SELECT sr.sr_customer_sk
    FROM store_returns sr
    WHERE sr.sr_return_tax < 50
    GROUP BY sr.sr_customer_sk
    HAVING COUNT(*) >= 2
)
SELECT
    c.c_customer_id,
    cs.cs_item_sk,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_net_paid_inc_ship_tax) AS total_sales_inc_tax,
    AVG(sr.sr_return_amt) AS avg_return_amount,
    MAX(cs.cs_ext_wholesale_cost) AS max_wholesale_cost,
    (
        SELECT AVG(cs2.cs_net_paid_inc_ship_tax)
        FROM catalog_sales cs2
        WHERE cs2.cs_item_sk = cs.cs_item_sk
    ) AS avg_item_sales
FROM catalog_sales cs
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN store_returns sr
    ON sr.sr_customer_sk = c.c_customer_sk
WHERE c.c_current_hdemo_sk = 853
  AND c.c_birth_day = 15
  AND cs.cs_net_paid_inc_ship_tax > 3000
  AND sr.sr_return_tax < 50
  AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = c.c_customer_sk
          AND sr2.sr_reversed_charge > 200
    )
GROUP BY c.c_customer_id, cs.cs_item_sk
ORDER BY total_sales_inc_tax DESC
LIMIT 20
