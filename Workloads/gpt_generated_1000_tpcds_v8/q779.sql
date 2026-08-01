WITH sampled_sales AS (
   SELECT *
   FROM catalog_sales
   TABLESAMPLE BERNOULLI (10)
   WHERE cs_ext_sales_price > 1000
),
returns_joined AS (
   SELECT
       cr.cr_order_number,
       cr.cr_return_amount,
       cr.cr_return_quantity,
       cs.cs_bill_customer_sk,
       cs.cs_net_profit,
       cs.cs_ext_sales_price,
       cs.cs_quantity
   FROM sampled_sales cs
   JOIN catalog_returns cr
     ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
   WHERE cr.cr_return_amount > 50
),
high_profit_orders AS (
   SELECT cs_order_number
   FROM catalog_sales
   WHERE cs_net_profit > 500
),
high_return_orders AS (
   SELECT cr_order_number
   FROM catalog_returns
   WHERE cr_return_amount > 200
),
intersected_orders AS (
   SELECT order_number
   FROM (
       SELECT cs_order_number AS order_number FROM high_profit_orders
       INTERSECT
       SELECT cr_order_number AS order_number FROM high_return_orders
   )
)
SELECT *
FROM (
   SELECT
       rj.cr_order_number,
       rj.cs_bill_customer_sk,
       rj.cs_net_profit,
       rj.cs_ext_sales_price,
       rj.cr_return_amount,
       rj.cr_return_quantity,
       lt.total_return_amount,
       rank() OVER (PARTITION BY rj.cs_bill_customer_sk ORDER BY rj.cs_net_profit DESC) AS profit_rank
   FROM returns_joined rj
   LEFT JOIN LATERAL (
       SELECT SUM(cr_return_amount) AS total_return_amount
       FROM catalog_returns cr2
       WHERE cr2.cr_order_number = rj.cr_order_number
   ) lt ON true
   WHERE rj.cr_order_number IN (SELECT order_number FROM intersected_orders)

   UNION ALL

   SELECT
       NULL AS cr_order_number,
       cs.cs_bill_customer_sk,
       SUM(cs.cs_net_profit) AS cs_net_profit,
       NULL AS cs_ext_sales_price,
       NULL AS cr_return_amount,
       NULL AS cr_return_quantity,
       NULL AS total_return_amount,
       rank() OVER (PARTITION BY cs.cs_bill_customer_sk ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
   FROM sampled_sales cs
   GROUP BY cs.cs_bill_customer_sk
) final_result
LIMIT 100
