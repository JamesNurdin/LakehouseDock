WITH base AS (
   SELECT
       d.d_year,
       s.s_state,
       ca_store.ca_state AS store_address_state,
       p.p_promo_name,
       ss.ss_net_paid,
       ss.ss_net_profit,
       CASE WHEN ss.ss_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
       promo_l.max_promo_cost,
       (
           SELECT COUNT(*)
           FROM web_returns wr2
           WHERE wr2.wr_order_number = ws.ws_order_number
       ) AS web_return_cnt
   FROM date_dim d
   JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   JOIN customer_address ca_store ON ss.ss_addr_sk = ca_store.ca_address_sk
   LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
   LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
   LEFT JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
   LEFT JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
   LEFT JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
   LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_order_number = ws.ws_order_number
   CROSS JOIN LATERAL (
        SELECT MAX(p2.p_cost) AS max_promo_cost
        FROM promotion p2
        WHERE p2.p_start_date_sk <= d.d_date_sk
          AND p2.p_end_date_sk >= d.d_date_sk
   ) AS promo_l
   WHERE d.d_year = 2001
     AND s.s_state = 'CA'
     AND p.p_discount_active = 'Y'
     AND cc.cc_city = 'New York'
     AND wsite.web_state = 'TX'
     AND ca_store.ca_state = 'NY'
),
agg_store AS (
   SELECT
       d_year,
       s_state,
       profit_flag,
       COUNT(DISTINCT p_promo_name) AS distinct_promos,
       SUM(ss_net_paid) AS total_net_paid,
       AVG(ss_net_profit) AS avg_net_profit,
       MAX(max_promo_cost) AS max_active_promo_cost,
       SUM(web_return_cnt) AS total_web_returns
   FROM base
   GROUP BY GROUPING SETS (
       (d_year, s_state, profit_flag),
       (d_year, s_state),
       (d_year),
       ()
   )
),
agg_web AS (
   SELECT
       d_year,
       s_state,
       profit_flag,
       COUNT(DISTINCT p_promo_name) AS distinct_promos,
       SUM(ss_net_paid) AS total_net_paid,
       AVG(ss_net_profit) AS avg_net_profit,
       MAX(max_promo_cost) AS max_active_promo_cost,
       SUM(web_return_cnt) AS total_web_returns
   FROM base
   WHERE ss_net_paid > 0
   GROUP BY ROLLUP (d_year, s_state, profit_flag)
),
unioned AS (
   SELECT * FROM agg_store
   UNION
   SELECT * FROM agg_web
),
final AS (
   SELECT *
   FROM unioned u
   WHERE u.d_year IN (
       SELECT d_year FROM agg_store
       INTERSECT
       SELECT d_year FROM agg_web
   )
)
SELECT
   d_year,
   s_state,
   profit_flag,
   distinct_promos,
   total_net_paid,
   avg_net_profit,
   max_active_promo_cost,
   total_web_returns
FROM final
ORDER BY d_year DESC, s_state, profit_flag
LIMIT 100
