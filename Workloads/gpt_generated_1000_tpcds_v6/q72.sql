WITH
  store_sales_agg AS (
    SELECT
      ss.ss_item_sk,
      ss.ss_store_sk,
      SUM(ss.ss_ext_sales_price) AS store_sales_total,
      SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    GROUP BY ss.ss_item_sk, ss.ss_store_sk
  ),
  web_sales_agg AS (
    SELECT
      ws.ws_item_sk,
      SUM(ws.ws_ext_sales_price) AS web_sales_total,
      SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
  ),
  catalog_sales_agg AS (
    SELECT
      cs.cs_item_sk,
      SUM(cs.cs_ext_sales_price) AS catalog_sales_total,
      SUM(cs.cs_quantity) AS catalog_quantity
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk
  ),
  returns_agg AS (
    SELECT
      wr.wr_item_sk,
      SUM(wr.wr_return_amt) AS return_amount,
      SUM(wr.wr_return_quantity) AS return_quantity
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
  ),
  cs_mapping AS (
    SELECT DISTINCT
      cs.cs_item_sk,
      cs.cs_call_center_sk,
      cs.cs_warehouse_sk,
      cs.cs_promo_sk
    FROM catalog_sales cs
  ),
  ss_addr AS (
    SELECT ss.ss_item_sk, MIN(ss.ss_addr_sk) AS ss_addr_sk
    FROM store_sales ss
    GROUP BY ss.ss_item_sk
  ),
  ss_demo AS (
    SELECT ss.ss_item_sk, MIN(ss.ss_cdemo_sk) AS ss_cdemo_sk
    FROM store_sales ss
    GROUP BY ss.ss_item_sk
  ),
  ws_mapping AS (
    SELECT ws.ws_item_sk,
           MIN(ws.ws_web_page_sk) AS ws_web_page_sk,
           MIN(ws.ws_web_site_sk) AS ws_web_site_sk
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
  )
SELECT
  i_store.i_item_id,
  i_store.i_product_name,
  s.s_store_name,
  cc.cc_name AS call_center_name,
  w.w_warehouse_name,
  prom.p_promo_name,
  ss_agg.store_sales_total,
  ws_agg.web_sales_total,
  cs_agg.catalog_sales_total,
  ret_agg.return_amount,
  inv.inv_quantity_on_hand,
  ca.ca_city,
  cd.cd_gender
FROM store_sales_agg ss_agg
JOIN item i_store
  ON ss_agg.ss_item_sk = i_store.i_item_sk
JOIN store s
  ON ss_agg.ss_store_sk = s.s_store_sk
LEFT JOIN cs_mapping cm
  ON ss_agg.ss_item_sk = cm.cs_item_sk
LEFT JOIN call_center cc
  ON cm.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN warehouse w
  ON cm.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN promotion prom
  ON cm.cs_promo_sk = prom.p_promo_sk
LEFT JOIN inventory inv
  ON i_store.i_item_sk = inv.inv_item_sk
     AND w.w_warehouse_sk = inv.inv_warehouse_sk
LEFT JOIN ss_addr sa
  ON ss_agg.ss_item_sk = sa.ss_item_sk
LEFT JOIN customer_address ca
  ON sa.ss_addr_sk = ca.ca_address_sk
LEFT JOIN ss_demo sd
  ON ss_agg.ss_item_sk = sd.ss_item_sk
LEFT JOIN customer_demographics cd
  ON sd.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN web_sales_agg ws_agg
  ON i_store.i_item_sk = ws_agg.ws_item_sk
LEFT JOIN item i_web
  ON ws_agg.ws_item_sk = i_web.i_item_sk
LEFT JOIN ws_mapping wm
  ON i_store.i_item_sk = wm.ws_item_sk
LEFT JOIN web_page wp
  ON wm.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_site wsit
  ON wm.ws_web_site_sk = wsit.web_site_sk
LEFT JOIN catalog_sales_agg cs_agg
  ON i_store.i_item_sk = cs_agg.cs_item_sk
LEFT JOIN returns_agg ret_agg
  ON i_store.i_item_sk = ret_agg.wr_item_sk
WHERE EXISTS (
    SELECT 1 FROM inventory inv2
    WHERE inv2.inv_item_sk = i_store.i_item_sk
      AND inv2.inv_quantity_on_hand > 0
)
ORDER BY i_store.i_item_id, s.s_store_name
LIMIT 100
