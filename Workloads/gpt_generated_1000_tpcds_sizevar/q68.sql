WITH catalog_agg AS (
   SELECT
      cc.cc_call_center_sk,
      cc.cc_name,
      i.i_category,
      cs.cs_promo_sk,
      SUM(cs.cs_net_paid) AS total_net_paid,
      COUNT(*) AS order_cnt
   FROM catalog_sales cs
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   WHERE cc.cc_employees > 500000
   GROUP BY cc.cc_call_center_sk, cc.cc_name, i.i_category, cs.cs_promo_sk
),
web_agg AS (
   SELECT
      CAST(NULL AS INTEGER) AS cc_call_center_sk,
      CAST(NULL AS VARCHAR) AS cc_name,
      i.i_category,
      ws.ws_promo_sk,
      SUM(ws.ws_net_paid) AS total_net_paid,
      COUNT(*) AS order_cnt
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   WHERE ws.ws_quantity > 0
   GROUP BY i.i_category, ws.ws_promo_sk
),
sales_union AS (
   SELECT cc_call_center_sk, cc_name, i_category, cs_promo_sk AS promo_sk, total_net_paid, order_cnt
   FROM catalog_agg
   UNION ALL
   SELECT cc_call_center_sk, cc_name, i_category, ws_promo_sk AS promo_sk, total_net_paid, order_cnt
   FROM web_agg
)
SELECT
   p.p_promo_name,
   su.i_category,
   SUM(su.total_net_paid) AS sum_net_paid,
   SUM(su.order_cnt) AS total_orders,
   COUNT(DISTINCT su.cc_call_center_sk) AS distinct_call_centers
FROM sales_union su
FULL OUTER JOIN promotion p ON su.promo_sk = p.p_promo_sk
GROUP BY p.p_promo_name, su.i_category
ORDER BY sum_net_paid DESC
LIMIT 100
