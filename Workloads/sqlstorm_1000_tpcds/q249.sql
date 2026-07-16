WITH unified_sales AS (
    SELECT cs.cs_sold_date_sk AS sold_date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_bill_customer_sk AS customer_sk,
           cs.cs_quantity AS quantity,
           cs.cs_net_profit AS net_profit,
           'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           ss.ss_item_sk,
           ss.ss_customer_sk,
           ss.ss_quantity,
           ss.ss_net_profit,
           'store'
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_bill_customer_sk,
           ws.ws_quantity,
           ws.ws_net_profit,
           'web'
    FROM web_sales ws
)
SELECT d.d_year,
       i.i_category,
       us.channel,
       c.c_preferred_cust_flag,
       SUM(us.net_profit) AS total_net_profit,
       SUM(us.quantity) AS total_quantity,
       COUNT(*) AS transaction_cnt
FROM unified_sales us
JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
JOIN item i ON us.item_sk = i.i_item_sk
JOIN customer c ON us.customer_sk = c.c_customer_sk
WHERE d.d_year BETWEEN 1999 AND 2001
GROUP BY d.d_year, i.i_category, us.channel, c.c_preferred_cust_flag
ORDER BY total_net_profit DESC
LIMIT 100
