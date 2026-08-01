WITH profit_active AS (
  SELECT
    w.w_warehouse_id,
    'ACTIVE' AS promo_status,
    SUM(cs.cs_net_profit) AS total_profit,
    (SELECT AVG(cs2.cs_net_profit) FROM tpcds.catalog_sales cs2) AS avg_profit,
    array_agg(DISTINCT i.i_category) AS categories
  FROM tpcds.catalog_sales cs
  JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
  JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  WHERE p.p_discount_active = 'Y'
    AND w.w_country = 'United States'
    AND cc.cc_mkt_class LIKE '%Particular%'
    AND EXISTS (
      SELECT 1 FROM tpcds.call_center cc2
      WHERE cc2.cc_call_center_sk = cs.cs_call_center_sk
        AND cc2.cc_hours LIKE '%8AM%'
    )
  GROUP BY w.w_warehouse_id
),
profit_inactive AS (
  SELECT
    w.w_warehouse_id,
    'INACTIVE' AS promo_status,
    SUM(cs.cs_net_profit) AS total_profit,
    (SELECT AVG(cs2.cs_net_profit) FROM tpcds.catalog_sales cs2) AS avg_profit,
    array_agg(DISTINCT i.i_category) AS categories
  FROM tpcds.catalog_sales cs
  JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
  JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  WHERE p.p_discount_active = 'N'
    AND w.w_country = 'United States'
    AND cc.cc_mkt_class LIKE '%Written%'
    AND EXISTS (
      SELECT 1 FROM tpcds.catalog_page cp
      WHERE cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
        AND cp.cp_type = 'Promotion'
    )
  GROUP BY w.w_warehouse_id
)
SELECT *
FROM profit_active
UNION ALL
SELECT *
FROM profit_inactive
ORDER BY total_profit DESC
LIMIT 100
