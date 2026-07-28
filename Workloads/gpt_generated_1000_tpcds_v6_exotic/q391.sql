WITH base AS (
   SELECT
       ws.ws_ext_sales_price,
       ws.ws_net_profit,
       ws.ws_order_number,
       ws.ws_bill_customer_sk,
       ws.ws_bill_cdemo_sk,
       ws.ws_promo_sk,
       p.p_channel_tv,
       p.p_promo_name,
       cd.cd_gender AS gender,
       c.c_first_name,
       c.c_email_address,
       CASE WHEN p.p_channel_tv = 'Y' THEN 'TV' ELSE 'Other' END AS promo_channel,
       CONCAT(p.p_promo_name, ' - ', c.c_first_name) AS promo_customer_desc
   FROM tpcds.web_sales ws
   JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN tpcds.customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN tpcds.customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   WHERE regexp_like(p.p_promo_name, 'Holiday')
     AND substring(c.c_email_address, strpos(c.c_email_address, '@') + 1) = 'example.com'
)
SELECT
   promo_channel,
   gender,
   SUM(ws_ext_sales_price) AS total_sales,
   SUM(ws_net_profit) AS total_profit,
   COUNT(DISTINCT ws_order_number) AS num_orders,
   AVG(ws_ext_sales_price) AS avg_sales,
   (SELECT AVG(ws_net_profit) FROM tpcds.web_sales) AS overall_avg_profit,
   MIN(promo_customer_desc) AS sample_desc
FROM base
WHERE EXISTS (
   SELECT 1 FROM tpcds.web_sales ws2
   WHERE ws2.ws_bill_customer_sk = base.ws_bill_customer_sk
   GROUP BY ws2.ws_bill_customer_sk
   HAVING SUM(ws2.ws_ext_sales_price) > 100000
)
GROUP BY GROUPING SETS (
   (promo_channel, gender),
   (promo_channel),
   (gender),
   ()
)
ORDER BY promo_channel, gender
