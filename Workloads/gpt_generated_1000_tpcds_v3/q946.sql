WITH joined_data AS (
   SELECT
       ss.ss_ticket_number,
       ss.ss_net_profit AS ss_net_profit,
       ws.ws_net_profit AS ws_net_profit,
       ws.ws_order_number,
       s.s_store_name,
       web.web_name,
       ca.ca_state,
       cd.cd_gender
   FROM store_sales ss
   JOIN time_dim td_sales
     ON ss.ss_sold_time_sk = td_sales.t_time_sk
   JOIN customer c
     ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd
     ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN customer_address ca
     ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN store s
     ON ss.ss_store_sk = s.s_store_sk
   LEFT JOIN store_returns sr
     ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
   LEFT JOIN time_dim td_returns
     ON sr.sr_return_time_sk = td_returns.t_time_sk
   LEFT JOIN reason r
     ON sr.sr_reason_sk = r.r_reason_sk
   LEFT JOIN web_sales ws
     ON ws.ws_bill_customer_sk = c.c_customer_sk
   LEFT JOIN time_dim td_web
     ON ws.ws_sold_time_sk = td_web.t_time_sk
   LEFT JOIN ship_mode sm
     ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   LEFT JOIN warehouse w
     ON ws.ws_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN web_site web
     ON ws.ws_web_site_sk = web.web_site_sk
   LEFT JOIN web_page wp
     ON ws.ws_web_page_sk = wp.wp_web_page_sk
   LEFT JOIN customer c2
     ON wp.wp_customer_sk = c2.c_customer_sk
),
agg AS (
   SELECT
       s_store_name,
       web_name,
       ca_state,
       cd_gender,
       SUM(ss_net_profit) AS total_store_profit,
       SUM(ws_net_profit) AS total_web_profit,
       COUNT(DISTINCT ss_ticket_number) AS num_store_sales,
       COUNT(DISTINCT ws_order_number) AS num_web_orders
   FROM joined_data
   GROUP BY s_store_name, web_name, ca_state, cd_gender
)
SELECT
   s_store_name,
   web_name,
   ca_state,
   cd_gender,
   total_store_profit,
   total_web_profit,
   num_store_sales,
   num_web_orders,
   ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY total_store_profit DESC) AS store_profit_rank
FROM agg
ORDER BY total_store_profit DESC
LIMIT 100
