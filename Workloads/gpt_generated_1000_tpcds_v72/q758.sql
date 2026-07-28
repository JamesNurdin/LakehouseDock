WITH catalog_agg AS (
   SELECT
      cs.cs_warehouse_sk,
      SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
      SUM(cs.cs_net_profit) AS catalog_profit
   FROM catalog_sales cs
   JOIN warehouse w
     ON cs.cs_warehouse_sk = w.w_warehouse_sk
   WHERE regexp_like(w.w_street_name, '(?i)laurel')
   GROUP BY cs.cs_warehouse_sk
),
web_agg AS (
   SELECT
      ws.ws_warehouse_sk,
      wp.wp_type,
      CASE
         WHEN regexp_like(wp.wp_url, '^https?://[^/]+/promo') THEN 'Promo'
         ELSE 'Regular'
      END AS url_category,
      SUM(ws.ws_ext_sales_price) AS web_sales_amount,
      SUM(ws.ws_net_profit) AS web_profit,
      COUNT(*) AS web_order_cnt
   FROM web_sales ws
   JOIN web_page wp
     ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN warehouse w
     ON ws.ws_warehouse_sk = w.w_warehouse_sk
   WHERE wp.wp_url LIKE '%/products/%'
   GROUP BY ws.ws_warehouse_sk,
            wp.wp_type,
            CASE
               WHEN regexp_like(wp.wp_url, '^https?://[^/]+/promo') THEN 'Promo'
               ELSE 'Regular'
            END
)
SELECT
   w.w_warehouse_id,
   w.w_city || ', ' || w.w_state AS location,
   ca.catalog_sales_amount,
   wa.web_sales_amount,
   (ca.catalog_profit + wa.web_profit) AS total_profit,
   CASE
      WHEN (ca.catalog_profit + wa.web_profit) > 100000 THEN 'High'
      WHEN (ca.catalog_profit + wa.web_profit) BETWEEN 50000 AND 100000 THEN 'Medium'
      ELSE 'Low'
   END AS profit_category,
   wa.url_category,
   wa.wp_type,
   wa.web_order_cnt
FROM catalog_agg ca
JOIN web_agg wa
  ON ca.cs_warehouse_sk = wa.ws_warehouse_sk
JOIN warehouse w
  ON ca.cs_warehouse_sk = w.w_warehouse_sk
WHERE (ca.catalog_sales_amount + wa.web_sales_amount) > 50000
GROUP BY w.w_warehouse_id,
         w.w_city,
         w.w_state,
         ca.catalog_sales_amount,
         wa.web_sales_amount,
         ca.catalog_profit,
         wa.web_profit,
         wa.url_category,
         wa.wp_type,
         wa.web_order_cnt
HAVING COUNT(*) >= 1
ORDER BY total_profit DESC
LIMIT 100
