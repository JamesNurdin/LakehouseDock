WITH filtered_sales AS (
   SELECT
       c.c_customer_sk,
       c.c_email_address,
       regexp_extract(c.c_email_address, '@(.*)$', 1) AS email_domain,
       wsite.web_name,
       ws.ws_order_number AS order_number,
       ws.ws_net_profit AS net_profit,
       ca.ca_address_id
   FROM web_sales ws
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
   JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
   WHERE regexp_like(c.c_email_address, '^.*@example\\.com$')
     AND wsite.web_name LIKE '%Online%'
     AND substring(ca.ca_address_id, 1, 5) = 'AAAAA'
)
SELECT
   email_domain,
   web_name,
   COUNT(DISTINCT order_number) AS distinct_orders,
   SUM(net_profit) AS total_net_profit,
   AVG(net_profit) AS avg_net_profit
FROM (
   SELECT
       fs.email_domain,
       fs.web_name,
       fs.order_number,
       fs.net_profit,
       fs.c_customer_sk
   FROM filtered_sales fs
   WHERE EXISTS (
       SELECT 1
       FROM store_returns sr
       WHERE sr.sr_customer_sk = fs.c_customer_sk
         AND sr.sr_net_loss > 500
   )
) sub
GROUP BY email_domain, web_name
ORDER BY total_net_profit DESC
LIMIT 100
