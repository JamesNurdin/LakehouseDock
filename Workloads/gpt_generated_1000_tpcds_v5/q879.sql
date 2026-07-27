WITH sales_data AS (
   SELECT
       c.c_customer_id AS customer_id,
       SUM(cs.cs_net_paid) AS total_amount,
       'sales' AS source,
       CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'profit' ELSE 'loss' END AS profit_flag,
       (
           SELECT COUNT(DISTINCT cs2.cs_item_sk)
           FROM catalog_sales cs2
           WHERE cs2.cs_bill_customer_sk = c.c_customer_sk
       ) AS distinct_items
   FROM catalog_sales cs
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE sm.sm_carrier = 'UPS'
     AND c.c_current_hdemo_sk = 2064
     AND EXISTS (
         SELECT 1
         FROM inventory inv
         WHERE inv.inv_item_sk = cs.cs_item_sk
           AND inv.inv_quantity_on_hand > 0
     )
   GROUP BY c.c_customer_id, c.c_customer_sk
),
returns_data AS (
   SELECT
       c.c_customer_id AS customer_id,
       SUM(sr.sr_return_amt) AS total_amount,
       'returns' AS source,
       CASE WHEN SUM(sr.sr_net_loss) > 0 THEN 'loss' ELSE 'gain' END AS profit_flag,
       (
           SELECT COUNT(DISTINCT sr2.sr_item_sk)
           FROM store_returns sr2
           WHERE sr2.sr_customer_sk = c.c_customer_sk
       ) AS distinct_items
   FROM store_returns sr
   JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   WHERE i.i_category = 'Electronics'
     AND c.c_birth_country = 'United States'
   GROUP BY c.c_customer_id, c.c_customer_sk
)
SELECT *
FROM sales_data
UNION ALL
SELECT *
FROM returns_data
ORDER BY total_amount DESC
LIMIT 100
