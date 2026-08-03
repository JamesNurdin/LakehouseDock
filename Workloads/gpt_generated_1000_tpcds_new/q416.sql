WITH base1 AS (
   SELECT ws.ws_order_number,
          ws.ws_net_profit,
          ws.ws_ext_sales_price,
          sm.sm_carrier,
          td.t_meal_time,
          ws.ws_sold_time_sk,
          ws.ws_ship_mode_sk,
          ws.ws_web_site_sk,
          ws.ws_sold_date_sk,
          ws.ws_ship_date_sk
   FROM web_sales ws
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
   JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
   WHERE td.t_meal_time = 'lunch'
     AND td.t_am_pm = 'PM'
     AND sm.sm_carrier IN ('DHL', 'MSC')
     AND wsit.web_manager = 'John Ward'
     AND ws.ws_net_profit > 0
),
base2 AS (
   SELECT ws.ws_order_number,
          ws.ws_net_profit,
          ws.ws_ext_sales_price,
          sm.sm_carrier,
          td.t_meal_time,
          ws.ws_sold_time_sk,
          ws.ws_ship_mode_sk,
          ws.ws_web_site_sk,
          ws.ws_sold_date_sk,
          ws.ws_ship_date_sk
   FROM web_sales ws
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
   JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
   WHERE td.t_meal_time = 'dinner'
     AND td.t_am_pm = 'AM'
     AND sm.sm_carrier = 'PRIVATECARRIER'
     AND wsit.web_county = 'Mesa County'
     AND ws.ws_net_profit < 0
),
unioned AS (
   SELECT * FROM base1
   UNION
   SELECT * FROM base2
),
intersected AS (
   SELECT ws_order_number FROM unioned
   INTERSECT
   SELECT ws_order_number FROM base1
),
anti AS (
   SELECT ws_order_number
   FROM intersected
   WHERE ws_order_number NOT IN (SELECT ws_order_number FROM base2)
),
full_joined AS (
   SELECT
       COALESCE(ws.ws_order_number, sm.sm_ship_mode_sk) AS key_id,
       ws.ws_net_profit,
       sm.sm_carrier,
       td.t_meal_time,
       wsit.web_manager,
       ROW_NUMBER() OVER (PARTITION BY sm.sm_carrier ORDER BY ws.ws_net_profit DESC) AS rn,
       RANK() OVER (ORDER BY ws.ws_net_profit DESC) AS rnk
   FROM web_sales ws
   FULL OUTER JOIN ship_mode sm
       ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   LEFT JOIN time_dim td
       ON ws.ws_sold_time_sk = td.t_time_sk
   LEFT JOIN web_site wsit
       ON ws.ws_web_site_sk = wsit.web_site_sk
   WHERE ws.ws_order_number IN (SELECT ws_order_number FROM anti)
)
SELECT
    key_id,
    ws_net_profit,
    sm_carrier,
    t_meal_time,
    web_manager,
    rn,
    rnk
FROM full_joined
WHERE rn <= 5
ORDER BY ws_net_profit DESC
LIMIT 100
