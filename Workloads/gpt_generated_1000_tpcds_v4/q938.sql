WITH catalog_agg AS (
    SELECT p.p_promo_id AS promo_id,
           d.d_year   AS year,
           SUM(cs.cs_net_paid)          AS net_paid,
           COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM catalog_sales cs
    JOIN date_dim d      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p     ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim t      ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE d.d_year = 2022
      AND p.p_discount_active = 'Y'
      AND t.t_am_pm = 'PM'
    GROUP BY p.p_promo_id, d.d_year
),
web_agg AS (
    SELECT p.p_promo_id AS promo_id,
           d.d_year   AS year,
           SUM(ws.ws_net_paid)          AS net_paid,
           COUNT(DISTINCT ws.ws_order_number) AS order_cnt
    FROM web_sales ws
    JOIN date_dim d      ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p     ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim t      ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE d.d_year = 2022
      AND p.p_discount_active = 'Y'
      AND t.t_am_pm = 'PM'
    GROUP BY p.p_promo_id, d.d_year
)
SELECT promo_id,
       year,
       SUM(net_paid)  AS total_net_paid,
       SUM(order_cnt) AS total_orders
FROM (
    SELECT promo_id, year, net_paid, order_cnt FROM catalog_agg
    UNION ALL
    SELECT promo_id, year, net_paid, order_cnt FROM web_agg
) AS combined
GROUP BY promo_id, year
HAVING SUM(net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
