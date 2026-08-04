WITH base AS (
   SELECT
      ws.ws_order_number,
      ws.ws_net_profit,
      ws.ws_ext_sales_price,
      c.c_first_name,
      c.c_last_name,
      cd.cd_gender,
      d.d_year,
      d.d_date,
      t.t_hour AS t_hour,
      w.w_warehouse_sk,
      w.w_state,
      st.s_store_sk,
      st.s_state,
      web.web_site_sk,
      web.web_name
   FROM web_sales ws
   JOIN date_dim d               ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN time_dim t               ON ws.ws_sold_time_sk = t.t_time_sk
   JOIN customer c               ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   JOIN warehouse w              ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN store st                 ON st.s_closed_date_sk = d.d_date_sk
   JOIN web_site web             ON ws.ws_web_site_sk = web.web_site_sk
   WHERE d.d_year = 2000
     AND cd.cd_gender = 'M'
     AND w.w_state = 'CA'
     AND web.web_street_type = 'Ave'
     AND t.t_hour BETWEEN 8 AND 12
),
returns_exist AS (
   SELECT b.*
   FROM base b
   WHERE EXISTS (
       SELECT 1
       FROM web_returns wr
       WHERE wr.wr_order_number = b.ws_order_number
         AND wr.wr_return_quantity > 0
   )
),
profit_positive AS (
   SELECT ws_order_number FROM returns_exist WHERE ws_net_profit > 0
),
profit_negative AS (
   SELECT ws_order_number FROM returns_exist WHERE ws_net_profit < 0
),
positive_not_negative AS (
   SELECT ws_order_number FROM profit_positive
   EXCEPT
   SELECT ws_order_number FROM profit_negative
),
union_set AS (
   SELECT ws_order_number, ws_net_profit, t_hour
   FROM returns_exist
   WHERE t_hour < 10
   UNION
   SELECT ws_order_number, ws_net_profit, t_hour
   FROM returns_exist
   WHERE t_hour >= 10
),
intersect_set AS (
   SELECT ws_order_number FROM positive_not_negative
   INTERSECT
   SELECT ws_order_number FROM union_set
)
SELECT
   re.ws_order_number,
   re.c_first_name,
   re.c_last_name,
   re.ws_net_profit,
   RANK() OVER (PARTITION BY re.d_year ORDER BY re.ws_net_profit DESC) AS profit_rank
FROM returns_exist re
WHERE re.ws_order_number IN (SELECT ws_order_number FROM intersect_set)
ORDER BY profit_rank ASC, re.ws_net_profit DESC
LIMIT 100
