WITH cs_filtered AS (
   SELECT
       cs.cs_bill_customer_sk AS customer_sk,
       cs.cs_net_profit,
       cs.cs_ext_sales_price,
       i.i_item_desc,
       c.c_email_address,
       c.c_first_name,
       c.c_last_name,
       CASE WHEN cs.cs_net_profit > 1000 THEN 'HIGH' ELSE 'LOW' END AS profit_level,
       cs.cs_item_sk
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   WHERE REGEXP_LIKE(i.i_item_desc, '^.*[A-Z]{3}.*$')
     AND c.c_email_address LIKE '%@example.com'
     AND EXISTS (
        SELECT 1 FROM inventory inv
        WHERE inv.inv_item_sk = cs.cs_item_sk
          AND inv.inv_quantity_on_hand > 0
     )
),
cs_customers AS (
   SELECT DISTINCT customer_sk FROM cs_filtered
),
ss_customers AS (
   SELECT DISTINCT ss.ss_customer_sk AS customer_sk
   FROM store_sales ss
   JOIN customer c2 ON ss.ss_customer_sk = c2.c_customer_sk
   WHERE c2.c_email_address LIKE '%@example.com'
),
new_customers AS (
   SELECT customer_sk FROM cs_customers
   EXCEPT
   SELECT customer_sk FROM ss_customers
),
final AS (
   SELECT
       nc.customer_sk,
       c.c_first_name,
       c.c_last_name,
       CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
       COUNT(*) AS purchase_count,
       SUM(cs.cs_net_profit) AS total_profit,
       CASE WHEN SUM(cs.cs_net_profit) > 5000 THEN 'VIP' ELSE 'NORMAL' END AS customer_segment,
       REGEXP_EXTRACT(cs.i_item_desc, '(\\d{3})') AS extracted_code
   FROM new_customers nc
   JOIN cs_filtered cs ON cs.customer_sk = nc.customer_sk
   JOIN customer c ON c.c_customer_sk = nc.customer_sk
   GROUP BY nc.customer_sk, c.c_first_name, c.c_last_name, cs.i_item_desc
)
SELECT
   customer_sk,
   c_first_name,
   c_last_name,
   full_name,
   purchase_count,
   total_profit,
   customer_segment,
   extracted_code
FROM final
ORDER BY total_profit DESC
LIMIT 100
