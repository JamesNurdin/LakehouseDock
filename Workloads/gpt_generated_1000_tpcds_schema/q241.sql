WITH sales_agg AS (
     SELECT
         cs.cs_bill_customer_sk AS customer_sk,
         cs.cs_call_center_sk AS call_center_sk,
         cs.cs_promo_sk AS promo_sk,
         SUM(cs.cs_net_paid) AS total_net_paid,
         SUM(cs.cs_quantity) AS total_quantity
     FROM catalog_sales cs
     WHERE cs.cs_net_paid > 1000
     GROUP BY cs.cs_bill_customer_sk, cs.cs_call_center_sk, cs.cs_promo_sk
 ),
 customer_info AS (
     SELECT
         c.c_customer_sk,
         c.c_first_name,
         c.c_last_name,
         cd.cd_credit_rating,
         cd.cd_purchase_estimate
     FROM customer c
     JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
     WHERE cd.cd_credit_rating = 'Good'
 ),
 call_center_info AS (
     SELECT
         cc.cc_call_center_sk,
         cc.cc_state,
         cc.cc_name
     FROM call_center cc
     WHERE cc.cc_state = 'CA'
 ),
 promotion_info AS (
     SELECT
         p.p_promo_sk,
         p.p_channel_press
     FROM promotion p
     WHERE p.p_channel_press = 'N'
 ),
 store_ret AS (
     SELECT
         sr.sr_customer_sk,
         sr.sr_return_amt,
         r.r_reason_desc
     FROM store_returns sr
     JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
     WHERE r.r_reason_desc LIKE '%damaged%'
 )
 SELECT
     ci.c_customer_sk,
     ci.c_first_name,
     ci.c_last_name,
     ci.cd_credit_rating,
     ca.total_net_paid,
     ca.total_quantity,
     cc.cc_name,
     cc.cc_state,
     p.p_channel_press,
     sr.sr_return_amt,
     sr.r_reason_desc,
     RANK() OVER (PARTITION BY cc.cc_call_center_sk ORDER BY ca.total_net_paid DESC) AS call_center_rank,
     (SELECT AVG(sa.total_net_paid) FROM sales_agg sa WHERE sa.customer_sk = ci.c_customer_sk) AS avg_customer_net_paid
 FROM sales_agg ca
 FULL OUTER JOIN customer_info ci ON ca.customer_sk = ci.c_customer_sk
 JOIN call_center_info cc ON ca.call_center_sk = cc.cc_call_center_sk
 JOIN promotion_info p ON ca.promo_sk = p.p_promo_sk
 LEFT JOIN store_ret sr ON sr.sr_customer_sk = ci.c_customer_sk
 WHERE ci.c_customer_sk IN (
     SELECT customer_sk FROM sales_agg WHERE total_net_paid > 5000
     INTERSECT
     SELECT sr_customer_sk FROM store_ret
 )
 ORDER BY call_center_rank, ci.c_last_name
 OFFSET 10
 LIMIT 100
