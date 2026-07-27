WITH base AS (
   SELECT
       cc.cc_call_center_sk,
       cc.cc_name,
       cc.cc_state,
       p.p_promo_sk,
       p.p_promo_name,
       d_sold.d_year,
       d_sold.d_month_seq,
       cs.cs_net_profit AS net_profit,
       CASE
           WHEN cs.cs_net_profit > 1000 THEN 'High'
           WHEN cs.cs_net_profit > 0    THEN 'Medium'
           ELSE 'Low'
       END AS profit_category,
       hd.hd_income_band_sk,
       cd.cd_credit_rating,
       i.inv_quantity_on_hand
   FROM catalog_sales cs
   JOIN date_dim d_sold
     ON cs.cs_sold_date_sk = d_sold.d_date_sk
   JOIN call_center cc
     ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp
     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN promotion p
     ON cs.cs_promo_sk = p.p_promo_sk
   JOIN customer_demographics cd
     ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd
     ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN inventory i
     ON i.inv_date_sk = d_sold.d_date_sk
   WHERE d_sold.d_year = 2002
     AND cc.cc_state = 'CA'
     AND p.p_discount_active = 'Y'
     AND hd.hd_income_band_sk BETWEEN 5 AND 15
     AND EXISTS (
         SELECT 1
         FROM promotion p2
         WHERE p2.p_promo_sk = cs.cs_promo_sk
           AND p2.p_channel_tv = 'Y'
     )
),
agg AS (
   SELECT
       cc_name,
       p_promo_name,
       d_month_seq,
       SUM(net_profit) AS total_profit,
       COUNT(*)       AS sales_cnt,
       AVG(net_profit) AS avg_profit,
       CASE
           WHEN SUM(net_profit) > 5000 THEN 'Excellent'
           WHEN SUM(net_profit) > 2000 THEN 'Good'
           ELSE 'Average'
       END AS profit_level
   FROM base
   GROUP BY ROLLUP (cc_name, p_promo_name, d_month_seq)
)
SELECT
   cc_name,
   p_promo_name,
   d_month_seq,
   total_profit,
   sales_cnt,
   avg_profit,
   profit_level,
   ROW_NUMBER() OVER (PARTITION BY cc_name ORDER BY total_profit DESC) AS profit_rank,
   CASE
       WHEN total_profit > (SELECT AVG(total_profit) FROM agg) THEN 'Above Avg'
       ELSE 'Below Avg'
   END AS comparison_to_avg
FROM agg
WHERE total_profit IS NOT NULL
ORDER BY cc_name, profit_rank
LIMIT 100
