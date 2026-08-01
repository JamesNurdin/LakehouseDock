/*
Goal: Analyze net paid sales and returns by year, state, and item category for low‑risk customers in the United States, comparing 2002 and 2003 while accounting for inventory levels and promotion costs. The query samples sales, uses a lateral subquery for promotion totals, filters with an EXISTS semi‑join, aggregates with CUBE, applies HAVING, and combines two yearly result sets with UNION before a final aggregation and ordering.
*/
WITH sampled_sales AS (
   SELECT *
   FROM catalog_sales
   TABLESAMPLE BERNOULLI (5)
),
sales_agg AS (
   SELECT 
      d_sold.d_year,
      s.s_state,
      i.i_category,
      SUM(cs.cs_net_paid)               AS total_net_paid,
      AVG(cs.cs_quantity)               AS avg_quantity,
      COUNT(DISTINCT cs.cs_order_number) AS unique_orders,
      SUM(sr.sr_return_amt)             AS total_return_amt,
      SUM(inv.inv_quantity_on_hand)     AS total_on_hand,
      MAX(promo_l.total_promo_cost)     AS max_promo_cost
   FROM sampled_sales cs
   JOIN date_dim d_sold
     ON cs.cs_sold_date_sk = d_sold.d_date_sk
   JOIN customer_demographics cd_bill
     ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
   JOIN warehouse w
     ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN item i
     ON cs.cs_item_sk = i.i_item_sk
   LEFT JOIN inventory inv
     ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
        AND inv.inv_date_sk = d_sold.d_date_sk
   JOIN store_returns sr
     ON sr.sr_item_sk = i.i_item_sk
   JOIN store s
     ON sr.sr_store_sk = s.s_store_sk
   JOIN date_dim d_return
     ON sr.sr_returned_date_sk = d_return.d_date_sk
   CROSS JOIN LATERAL (
       SELECT SUM(p.p_cost) AS total_promo_cost
       FROM promotion p
       WHERE p.p_item_sk = i.i_item_sk
   ) AS promo_l
   WHERE d_sold.d_year = 2002
     AND cd_bill.cd_credit_rating = 'Low Risk'
     AND s.s_country = 'United States'
     AND EXISTS (
         SELECT 1
         FROM promotion p2
         WHERE p2.p_promo_sk = cs.cs_promo_sk
           AND p2.p_discount_active = 'Y'
     )
   GROUP BY CUBE (d_sold.d_year, s.s_state, i.i_category)
   HAVING SUM(cs.cs_net_paid) > 10000
),
sales_agg_2003 AS (
   SELECT 
      d_sold.d_year,
      s.s_state,
      i.i_category,
      SUM(cs.cs_net_paid)               AS total_net_paid,
      AVG(cs.cs_quantity)               AS avg_quantity,
      COUNT(DISTINCT cs.cs_order_number) AS unique_orders,
      SUM(sr.sr_return_amt)             AS total_return_amt,
      SUM(inv.inv_quantity_on_hand)     AS total_on_hand,
      MAX(promo_l.total_promo_cost)     AS max_promo_cost
   FROM sampled_sales cs
   JOIN date_dim d_sold
     ON cs.cs_sold_date_sk = d_sold.d_date_sk
   JOIN customer_demographics cd_bill
     ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
   JOIN warehouse w
     ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN item i
     ON cs.cs_item_sk = i.i_item_sk
   LEFT JOIN inventory inv
     ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
        AND inv.inv_date_sk = d_sold.d_date_sk
   JOIN store_returns sr
     ON sr.sr_item_sk = i.i_item_sk
   JOIN store s
     ON sr.sr_store_sk = s.s_store_sk
   JOIN date_dim d_return
     ON sr.sr_returned_date_sk = d_return.d_date_sk
   CROSS JOIN LATERAL (
       SELECT SUM(p.p_cost) AS total_promo_cost
       FROM promotion p
       WHERE p.p_item_sk = i.i_item_sk
   ) AS promo_l
   WHERE d_sold.d_year = 2003
     AND cd_bill.cd_credit_rating = 'Low Risk'
     AND s.s_country = 'United States'
     AND EXISTS (
         SELECT 1
         FROM promotion p2
         WHERE p2.p_promo_sk = cs.cs_promo_sk
           AND p2.p_discount_active = 'Y'
     )
   GROUP BY CUBE (d_sold.d_year, s.s_state, i.i_category)
   HAVING SUM(cs.cs_net_paid) > 10000
),
union_data AS (
   SELECT d_year, s_state, i_category, total_net_paid
   FROM sales_agg
   UNION
   SELECT d_year, s_state, i_category, total_net_paid
   FROM sales_agg_2003
)
SELECT 
   d_year,
   s_state,
   i_category,
   SUM(total_net_paid) AS net_paid_sum
FROM union_data
GROUP BY CUBE (d_year, s_state, i_category)
ORDER BY net_paid_sum DESC
LIMIT 100
