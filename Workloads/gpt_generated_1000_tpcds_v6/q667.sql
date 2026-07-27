WITH joined AS (
   SELECT
       ws.ws_net_profit,
       ws.ws_ext_sales_price,
       td.t_meal_time,
       s.web_gmt_offset,
       s.web_name,
       w.w_warehouse_name,
       p.p_promo_name,
       p.p_discount_active
   FROM web_sales ws
   JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
   JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   WHERE td.t_meal_time = 'dinner'
     AND s.web_gmt_offset BETWEEN -8.00 AND -5.00
     AND p.p_discount_active = 'Y'
),
agg AS (
   SELECT
       j.web_name,
       j.w_warehouse_name,
       j.p_promo_name,
       SUM(j.ws_net_profit) AS total_profit,
       SUM(j.ws_ext_sales_price) AS total_sales,
       COUNT(*) AS order_count
   FROM joined j
   GROUP BY j.web_name, j.w_warehouse_name, j.p_promo_name
)
SELECT
   web_name,
   w_warehouse_name,
   p_promo_name,
   total_profit,
   total_sales,
   order_count,
   RANK() OVER (PARTITION BY web_name ORDER BY total_profit DESC) AS profit_rank,
   AVG(total_profit) OVER (PARTITION BY web_name ORDER BY total_profit
                           ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS profit_moving_avg
FROM agg
ORDER BY web_name, profit_rank
LIMIT 100
