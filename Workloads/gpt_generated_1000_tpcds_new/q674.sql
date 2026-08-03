WITH purchase_customers AS (
   SELECT cs.cs_bill_customer_sk AS customer_sk
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
   UNION
   SELECT ws.ws_bill_customer_sk
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
),
return_customers AS (
   SELECT cr.cr_refunded_customer_sk AS customer_sk
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
   UNION
   SELECT wr.wr_refunded_customer_sk
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
),
active_customers AS (
   SELECT pc.customer_sk
   FROM purchase_customers pc
   EXCEPT
   SELECT rc.customer_sk
   FROM return_customers rc
),
profit_union AS (
   SELECT cs.cs_bill_customer_sk AS customer_sk,
          d.d_year AS year,
          SUM(cs.cs_net_profit) AS total_profit,
          CASE WHEN SUM(cs.cs_quantity) > 100 THEN 'BIG' ELSE 'SMALL' END AS size_category
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   WHERE d.d_year = 2001
     AND p.p_discount_active = 'Y'
   GROUP BY cs.cs_bill_customer_sk, d.d_year
   UNION
   SELECT ws.ws_bill_customer_sk,
          d.d_year,
          SUM(ws.ws_net_profit),
          CASE WHEN SUM(ws.ws_quantity) > 100 THEN 'BIG' ELSE 'SMALL' END
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   WHERE d.d_year = 2001
     AND p.p_discount_active = 'Y'
   GROUP BY ws.ws_bill_customer_sk, d.d_year
)
SELECT pu.customer_sk,
       pu.year,
       pu.total_profit,
       pu.size_category,
       (SELECT c.c_first_name || ' ' || c.c_last_name
          FROM customer c
         WHERE c.c_customer_sk = pu.customer_sk) AS customer_name
FROM profit_union pu
JOIN active_customers ac ON pu.customer_sk = ac.customer_sk
ORDER BY pu.total_profit DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
