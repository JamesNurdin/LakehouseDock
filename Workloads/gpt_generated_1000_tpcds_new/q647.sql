WITH web_sample AS (
   SELECT
       ws.ws_bill_customer_sk,
       ws.ws_bill_cdemo_sk,
       ws.ws_bill_addr_sk,
       ws.ws_sales_price,
       ws.ws_quantity,
       ws.ws_sold_date_sk
   FROM web_sales ws
   TABLESAMPLE BERNOULLI (5)
   WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450500
)
SELECT
    combined.c_customer_id,
    combined.channel,
    combined.total_amount,
    combined.cust_total_sales
FROM (
   SELECT
       c.c_customer_sk,
       c.c_customer_id,
       'WEB' AS channel,
       ws.ws_sales_price * ws.ws_quantity AS total_amount,
       l.cust_total_sales
   FROM web_sample ws
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   JOIN LATERAL (
        SELECT sum(ws2.ws_sales_price * ws2.ws_quantity) AS cust_total_sales
        FROM web_sales ws2
        WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
   ) l ON true
   WHERE cd.cd_gender = 'M'
   UNION ALL
   SELECT
       c2.c_customer_sk,
       c2.c_customer_id,
       'STORE' AS channel,
       sr.sr_return_amt * sr.sr_return_quantity AS total_amount,
       CAST(NULL AS decimal(15,2)) AS cust_total_sales
   FROM store_returns sr
   JOIN customer c2 ON sr.sr_customer_sk = c2.c_customer_sk
   JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
   WHERE ca.ca_state = 'CA'
) AS combined
WHERE combined.c_customer_sk NOT IN (
    SELECT sr2.sr_customer_sk
    FROM store_returns sr2
    WHERE sr2.sr_return_amt > 2000
)
LIMIT 100
