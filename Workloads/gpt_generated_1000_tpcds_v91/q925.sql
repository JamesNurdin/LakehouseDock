WITH
  call_center_hours AS (
    SELECT
      cc.cc_call_center_sk,
      hour_part
    FROM
      call_center cc
    CROSS JOIN UNNEST(split(cc.cc_hours, ',')) AS t (hour_part)
    WHERE
      regexp_like(cc.cc_mkt_desc, '(?i)danger|dangerous')
      AND cc.cc_city LIKE 'New%'
  ),
  call_center_sales AS (
    SELECT
      cs.cs_promo_sk,
      cs.cs_warehouse_sk,
      cs.cs_call_center_sk,
      SUM(cs.cs_net_paid) AS total_cs_net_paid,
      COUNT(*) AS cnt_cs_orders,
      AVG(cs.cs_quantity) AS avg_cs_quantity
    FROM
      catalog_sales cs
    GROUP BY
      cs.cs_promo_sk,
      cs.cs_warehouse_sk,
      cs.cs_call_center_sk
  ),
  web_sales_agg AS (
    SELECT
      ws.ws_promo_sk,
      ws.ws_warehouse_sk,
      SUM(ws.ws_net_paid) AS total_ws_net_paid,
      COUNT(*) AS cnt_ws_orders,
      AVG(ws.ws_quantity) AS avg_ws_quantity
    FROM
      web_sales ws
    GROUP BY
      ws.ws_promo_sk,
      ws.ws_warehouse_sk
  )
SELECT
  p.p_promo_name,
  w.w_warehouse_name,
  ccs.total_cs_net_paid,
  wsa.total_ws_net_paid,
  (ccs.total_cs_net_paid - wsa.total_ws_net_paid) AS net_paid_diff,
  concat(cc.cc_city, ', ', cc.cc_state) AS location,
  substring(cc.cc_zip FROM 1 FOR 5) AS zip_prefix,
  regexp_extract(cc.cc_mkt_desc, '(?i)(dangerous|danger)', 1) AS matched_desc,
  ch.hour_part AS hour_segment,
  (SELECT MAX(cs_sub.cs_net_paid) FROM catalog_sales cs_sub WHERE cs_sub.cs_call_center_sk = cc.cc_call_center_sk) AS max_cs_net_paid_for_cc,
  CASE
    WHEN ccs.avg_cs_quantity > (SELECT AVG(cs2.cs_quantity) FROM catalog_sales cs2) THEN 'ABOVE_AVG'
    ELSE 'BELOW_AVG'
  END AS quantity_vs_global_avg
FROM
  call_center_sales ccs
JOIN promotion p ON ccs.cs_promo_sk = p.p_promo_sk
JOIN warehouse w ON ccs.cs_warehouse_sk = w.w_warehouse_sk
JOIN web_sales_agg wsa ON wsa.ws_promo_sk = ccs.cs_promo_sk
  AND wsa.ws_warehouse_sk = ccs.cs_warehouse_sk
JOIN call_center cc ON cc.cc_call_center_sk = ccs.cs_call_center_sk
JOIN call_center_hours ch ON ch.cc_call_center_sk = cc.cc_call_center_sk
WHERE
  ccs.total_cs_net_paid > (SELECT SUM(cs_total.cs_net_paid) FROM catalog_sales cs_total) / 1000
ORDER BY
  net_paid_diff DESC
LIMIT 100
