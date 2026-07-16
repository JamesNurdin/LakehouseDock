WITH sales_agg AS (
   SELECT
       c.c_customer_sk,
       d.d_year,
       d.d_quarter_seq,
       i.i_category,
       sum(ss.ss_net_profit) AS net_profit,
       count(*) AS orders,
       'store' AS channel
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   WHERE d.d_year = 2001
   GROUP BY c.c_customer_sk, d.d_year, d.d_quarter_seq, i.i_category
   UNION ALL
   SELECT
       c.c_customer_sk,
       d.d_year,
       d.d_quarter_seq,
       i.i_category,
       sum(cs.cs_net_profit) AS net_profit,
       count(*) AS orders,
       'catalog' AS channel
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   WHERE d.d_year = 2001
   GROUP BY c.c_customer_sk, d.d_year, d.d_quarter_seq, i.i_category
   UNION ALL
   SELECT
       c.c_customer_sk,
       d.d_year,
       d.d_quarter_seq,
       i.i_category,
       sum(ws.ws_net_profit) AS net_profit,
       count(*) AS orders,
       'web' AS channel
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   WHERE d.d_year = 2001
   GROUP BY c.c_customer_sk, d.d_year, d.d_quarter_seq, i.i_category
), customer_totals AS (
   SELECT
       sa.c_customer_sk,
       c.c_first_name,
       c.c_last_name,
       c.c_email_address,
       ca.ca_state,
       sum(sa.net_profit) AS total_net_profit,
       sum(sa.orders) AS total_orders,
       count(DISTINCT sa.channel) AS channels_used
   FROM sales_agg sa
   JOIN customer c ON sa.c_customer_sk = c.c_customer_sk
   LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
   GROUP BY sa.c_customer_sk, c.c_first_name, c.c_last_name, c.c_email_address, ca.ca_state
)
SELECT
   profit_rank,
   c_customer_sk,
   c_first_name,
   c_last_name,
   c_email_address,
   ca_state,
   total_net_profit,
   total_orders,
   channels_used
FROM (
   SELECT
       c_customer_sk,
       c_first_name,
       c_last_name,
       c_email_address,
       ca_state,
       total_net_profit,
       total_orders,
       channels_used,
       rank() OVER (ORDER BY total_net_profit DESC) AS profit_rank
   FROM customer_totals
) ranked
WHERE profit_rank <= 10
ORDER BY profit_rank
