WITH sales_join AS (
   SELECT
       cs.cs_order_number,
       cs.cs_sold_date_sk,
       d.d_year,
       cs.cs_bill_customer_sk,
       c.c_customer_id,
       cs.cs_item_sk,
       i.i_item_id,
       i.i_brand,
       cs.cs_quantity,
       cs.cs_net_paid,
       cs.cs_net_profit,
       cs.cs_ext_sales_price,
       cs.cs_ext_wholesale_cost,
       p.p_promo_id,
       p.p_discount_active,
       ws.web_site_id,
       ws.web_state,
       CASE 
           WHEN cs.cs_net_profit > 1000 THEN 'HIGH'
           WHEN cs.cs_net_profit > 0   THEN 'MEDIUM'
           ELSE 'LOW'
       END AS profit_category
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN web_site ws ON d.d_date_sk = ws.web_open_date_sk
   WHERE d.d_year = 2001
     AND i.i_brand = 'Brand#12'
     AND p.p_discount_active = 'Y'
     AND cs.cs_quantity > 1
     AND cs.cs_net_profit > 0
     AND ws.web_state = 'CA'
),
agg AS (
   SELECT
       sj.c_customer_id,
       sj.i_item_id,
       sj.i_brand,
       sj.d_year,
       SUM(sj.cs_net_paid)   AS total_net_paid,
       SUM(sj.cs_net_profit) AS total_profit,
       COUNT(*)               AS order_count,
       MAX(sj.profit_category) AS highest_profit_category
   FROM sales_join sj
   GROUP BY sj.c_customer_id, sj.i_item_id, sj.i_brand, sj.d_year
)
SELECT
   a.c_customer_id,
   a.i_item_id,
   a.i_brand,
   a.d_year,
   a.total_net_paid,
   a.total_profit,
   a.order_count,
   a.highest_profit_category,
   RANK() OVER (PARTITION BY a.d_year ORDER BY a.total_net_paid DESC) AS sales_rank
FROM agg a
ORDER BY sales_rank
LIMIT 100
