WITH promo_sales AS (
   SELECT
       p.p_promo_id,
       p.p_promo_name,
       regexp_extract(p.p_channel_details, '(\\w+)', 1) AS channel_keyword,
       d.d_year,
       SUM(ws.ws_net_profit) AS total_profit,
       COUNT(*) AS sales_cnt,
       CASE WHEN SUM(ws.ws_net_profit) >= 0 THEN 'Profit' ELSE 'Loss' END AS profit_status
   FROM web_sales ws
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
   WHERE regexp_like(p.p_promo_name, 'Discount')
     AND ca.ca_street_name LIKE '%Hill%'
     AND EXISTS (
         SELECT 1
         FROM customer_demographics cd
         WHERE cd.cd_demo_sk = ws.ws_bill_cdemo_sk
           AND cd.cd_marital_status = 'M'
     )
   GROUP BY p.p_promo_id, p.p_promo_name, p.p_channel_details, d.d_year
),
avg_profit AS (
   SELECT AVG(total_profit) AS avg_total_profit FROM promo_sales
)
SELECT
   ps.p_promo_id,
   substring(ps.p_promo_name, 1, 10) AS promo_name_prefix,
   ps.channel_keyword,
   ps.d_year,
   ps.total_profit,
   ps.sales_cnt,
   ps.profit_status,
   (substring(ps.p_promo_name, 1, 10) || '_' || ps.channel_keyword) AS promo_channel_key,
   CASE 
       WHEN ps.total_profit > ap.avg_total_profit THEN 'Above Avg'
       ELSE 'Below Avg'
   END AS profit_vs_avg
FROM promo_sales ps
CROSS JOIN avg_profit ap
ORDER BY ps.total_profit DESC
LIMIT 100
