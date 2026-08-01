WITH first_orders AS (
   SELECT
       cs.cs_order_number,
       cs.cs_bill_customer_sk,
       cs.cs_sold_date_sk,
       cs.cs_ext_sales_price,
       cs.cs_ext_discount_amt,
       cs.cs_net_profit,
       cs.cs_net_paid,
       ROW_NUMBER() OVER (ORDER BY cs.cs_net_profit DESC) AS global_rn,
       LAG(cs.cs_net_paid) OVER (PARTITION BY cs.cs_bill_customer_sk ORDER BY cs.cs_sold_date_sk) AS prev_net_paid,
       SUM(cs.cs_ext_sales_price) OVER (PARTITION BY cs.cs_bill_customer_sk ORDER BY cs.cs_sold_date_sk
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales,
       CASE WHEN cs.cs_ext_discount_amt > 1000 THEN 'High Discount' ELSE 'Low Discount' END AS discount_category,
       (SELECT AVG(p2.p_cost) FROM promotion p2 WHERE p2.p_promo_sk = cs.cs_promo_sk) AS avg_promo_cost
   FROM catalog_sales cs
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   WHERE p.p_discount_active = 'Y'
     AND cs.cs_ext_list_price > 5000
     AND cp.cp_department = 'Books'
),
second_orders AS (
   SELECT cs.cs_order_number
   FROM catalog_sales cs
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   WHERE w.w_state = 'CA'
     AND c.c_last_review_date >= 2452500
     AND cs.cs_quantity >= 5
),
filtered_keys AS (
   SELECT cs_order_number
   FROM first_orders
   EXCEPT
   SELECT cs_order_number
   FROM second_orders
)
SELECT
   fo.cs_order_number,
   fo.cs_bill_customer_sk,
   fo.cs_sold_date_sk,
   fo.cs_ext_sales_price,
   fo.cs_ext_discount_amt,
   fo.cs_net_profit,
   fo.global_rn,
   fo.prev_net_paid,
   fo.cumulative_sales,
   fo.discount_category,
   fo.avg_promo_cost
FROM first_orders fo
JOIN filtered_keys fk ON fo.cs_order_number = fk.cs_order_number
ORDER BY fo.global_rn
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
