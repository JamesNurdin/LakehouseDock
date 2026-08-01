WITH sampled_sales AS (
   SELECT ws_sold_date_sk,
          ws_net_paid,
          ws_ext_discount_amt,
          ws_promo_sk,
          ws_web_site_sk,
          ws_quantity,
          ws_order_number
   FROM   web_sales TABLESAMPLE BERNOULLI (10)
   WHERE  ws_quantity > 0
),
joined_data AS (
   SELECT
       ws.ws_order_number,
       ws.ws_sold_date_sk,
       ws.ws_net_paid,
       ws.ws_ext_discount_amt,
       cp.cp_catalog_page_id,
       cc.cc_state,
       d.d_year,
       p.p_channel_radio,
       p.p_purpose,
       ws.ws_web_site_sk,
       w.web_name,
       CASE WHEN ws.ws_ext_discount_amt > 0 THEN 'Y' ELSE 'N' END AS has_discount,
       ROW_NUMBER() OVER (PARTITION BY cc.cc_division ORDER BY ws.ws_net_paid DESC) AS rn_division,
       cc.cc_division
   FROM sampled_sales ws
   JOIN date_dim d      ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN promotion p     ON ws.ws_promo_sk     = p.p_promo_sk
   JOIN call_center cc  ON cc.cc_closed_date_sk = d.d_date_sk
   JOIN web_site w      ON ws.ws_web_site_sk   = w.web_site_sk
   JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND p.p_channel_radio = 'N'
     AND cc.cc_state = 'CA'
     AND w.web_country = 'United States'
     AND cp.cp_type = 'Catalog'
     AND ws.ws_net_paid > 0
     AND EXISTS (
         SELECT 1
         FROM   promotion p2
         WHERE  p2.p_promo_sk = ws.ws_promo_sk
           AND  p2.p_purpose = 'Unknown'
     )
),
agg_data AS (
   SELECT
       cc_division,
       SUM(ws_net_paid)      AS total_net_paid,
       COUNT(*)              AS order_cnt,
       AVG(ws_net_paid)      AS avg_net_paid
   FROM joined_data
   WHERE rn_division <= 5
   GROUP BY cc_division
),
union_set AS (
   SELECT cc_division FROM agg_data
   UNION
   SELECT cc_division FROM agg_data WHERE total_net_paid > 10000
),
intersect_set AS (
   SELECT cc_division FROM agg_data WHERE order_cnt > 10
   INTERSECT
   SELECT cc_division FROM agg_data WHERE avg_net_paid > 500
),
except_set AS (
   SELECT cc_division FROM agg_data
   EXCEPT
   SELECT cc_division FROM agg_data WHERE total_net_paid < 2000
),
final AS (
   SELECT
       a.cc_division,
       a.total_net_paid,
       a.order_cnt,
       a.avg_net_paid,
       CASE WHEN a.total_net_paid > 50000 THEN 'HIGH' ELSE 'NORMAL' END AS revenue_category,
       ROW_NUMBER() OVER (PARTITION BY a.cc_division ORDER BY a.total_net_paid DESC) AS rank_division
   FROM agg_data a
   WHERE a.cc_division IN (SELECT cc_division FROM intersect_set)
     AND a.cc_division NOT IN (SELECT cc_division FROM except_set)
)
SELECT
   cc_division,
   total_net_paid,
   order_cnt,
   avg_net_paid,
   revenue_category,
   rank_division
FROM final
ORDER BY revenue_category DESC, total_net_paid DESC
LIMIT 100
