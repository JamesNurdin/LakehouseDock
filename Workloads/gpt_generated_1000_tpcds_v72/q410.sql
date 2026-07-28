WITH catalog_agg AS (
   SELECT
       p.p_promo_name,
       td.t_hour AS sale_hour,
       SUM(cs.cs_net_paid) AS total_net_paid,
       COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
       (
           SELECT AVG(cs2.cs_ext_discount_amt)
           FROM catalog_sales cs2
           WHERE cs2.cs_promo_sk = p.p_promo_sk
       ) AS avg_discount
   FROM catalog_sales cs
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
   WHERE p.p_channel_email = 'Y'
     AND td.t_hour BETWEEN 9 AND 17
   GROUP BY p.p_promo_name, td.t_hour, p.p_promo_sk
),
web_agg AS (
   SELECT
       p.p_promo_name,
       td.t_hour AS sale_hour,
       SUM(ws.ws_net_paid) AS total_net_paid,
       COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
       (
           SELECT AVG(ws2.ws_ext_discount_amt)
           FROM web_sales ws2
           WHERE ws2.ws_promo_sk = p.p_promo_sk
       ) AS avg_discount
   FROM web_sales ws
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
   WHERE p.p_channel_email = 'Y'
     AND td.t_hour BETWEEN 9 AND 17
   GROUP BY p.p_promo_name, td.t_hour, p.p_promo_sk
)
SELECT DISTINCT
   ca.p_promo_name,
   ca.sale_hour,
   ca.total_net_paid,
   ca.distinct_customers,
   ca.avg_discount
FROM catalog_agg ca
WHERE ca.total_net_paid > 1000
UNION
SELECT DISTINCT
   wa.p_promo_name,
   wa.sale_hour,
   wa.total_net_paid,
   wa.distinct_customers,
   wa.avg_discount
FROM web_agg wa
WHERE wa.total_net_paid > 1000
ORDER BY total_net_paid DESC
LIMIT 100
