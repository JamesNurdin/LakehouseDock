WITH sales_cust AS (
   SELECT
       ws.ws_bill_customer_sk,
       ws.ws_order_number,
       ws.ws_net_profit,
       c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       c.c_email_address,
       wp.wp_url
   FROM tpcds.web_sales ws
   JOIN tpcds.customer c
       ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN tpcds.customer_demographics cd
       ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   JOIN tpcds.web_page wp
       ON ws.ws_web_page_sk = wp.wp_web_page_sk
   WHERE cd.cd_gender = 'M'
     AND regexp_like(c.c_email_address, '@example\\.com$')
     AND wp.wp_url LIKE '%.html'
)
SELECT
    c_customer_id,
    concat(c_first_name, ' ', c_last_name) AS full_name,
    regexp_extract(c_email_address, '@(.+)$', 1) AS email_domain,
    sum(ws_net_profit) AS total_profit,
    count(distinct ws_order_number) AS order_cnt
FROM sales_cust
GROUP BY c_customer_id, c_first_name, c_last_name, c_email_address
HAVING sum(ws_net_profit) > 1000
   AND count(distinct ws_order_number) > 5
ORDER BY total_profit DESC
LIMIT 100
