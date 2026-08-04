WITH sales_agg AS (
   SELECT
       ws.ws_promo_sk,
       ws.ws_web_site_sk,
       ws.ws_order_number,
       ws.ws_net_profit,
       wr.wr_fee,
       s.web_city
   FROM web_sales ws
   JOIN customer c
       ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN household_demographics hd
       ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   JOIN promotion p
       ON ws.ws_promo_sk = p.p_promo_sk
   JOIN web_site s
       ON ws.ws_web_site_sk = s.web_site_sk
   LEFT JOIN web_returns wr
       ON wr.wr_order_number = ws.ws_order_number
   WHERE s.web_country = 'United States'
     AND p.p_channel_radio = 'N'
     AND ws.ws_net_paid_inc_ship > 1000
),
grouped AS (
   SELECT
       sa.ws_promo_sk,
       sa.web_city,
       SUM(sa.ws_net_profit) AS total_profit,
       SUM(COALESCE(sa.wr_fee, 0)) AS total_return_fee,
       COUNT(DISTINCT sa.ws_order_number) AS orders
   FROM sales_agg sa
   GROUP BY sa.ws_promo_sk, sa.web_city
   HAVING COUNT(DISTINCT sa.ws_order_number) >= 5
),
ranked AS (
   SELECT
       g.ws_promo_sk,
       p.p_promo_name,
       g.web_city,
       g.total_profit,
       g.total_return_fee,
       g.orders,
       g.total_profit / NULLIF(g.orders, 0) AS avg_profit_per_order,
       ROW_NUMBER() OVER (PARTITION BY g.web_city ORDER BY g.total_profit / NULLIF(g.orders, 0) DESC) AS rnk
   FROM grouped g
   JOIN promotion p
       ON g.ws_promo_sk = p.p_promo_sk
)
SELECT
   ws_promo_sk,
   p_promo_name,
   web_city,
   total_profit,
   total_return_fee,
   orders,
   avg_profit_per_order,
   rnk
FROM ranked
WHERE rnk <= 3
ORDER BY web_city, rnk
