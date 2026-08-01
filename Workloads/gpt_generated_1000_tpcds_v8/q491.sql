WITH
  store_agg AS (
    SELECT
      p.p_promo_name        AS promo_name,
      td.t_hour             AS hour_of_day,
      SUM(ss.ss_ext_sales_price) AS store_sales,
      COUNT(DISTINCT ss.ss_store_sk) AS distinct_stores,
      COUNT(DISTINCT ca.ca_state)    AS distinct_states,
      CASE WHEN SUM(ss.ss_ext_sales_price) > 100000 THEN 'HIGH' ELSE 'LOW' END AS sales_category
    FROM store_sales ss
    JOIN store s               ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p           ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim td           ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer_address ca   ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE s.s_state = 'CA'
      AND td.t_hour = 10
      AND ss.ss_quantity > 1
    GROUP BY GROUPING SETS (
      (p.p_promo_name, td.t_hour),
      (p.p_promo_name),
      (td.t_hour)
    )
  ),
  web_agg AS (
    SELECT
      p.p_promo_name        AS promo_name,
      td.t_hour             AS hour_of_day,
      SUM(ws.ws_ext_sales_price) AS web_sales,
      COUNT(DISTINCT ws.ws_ship_mode_sk) AS distinct_ship_modes,
      COUNT(DISTINCT ca.ca_state)        AS distinct_states,
      CASE WHEN SUM(ws.ws_ext_sales_price) > 80000 THEN 'HIGH' ELSE 'LOW' END AS sales_category
    FROM web_sales ws
    JOIN promotion p           ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim td           ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer_address ca   ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm          ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_type = 'AIR'
      AND td.t_hour = 15
      AND ws.ws_quantity > 0
    GROUP BY ROLLUP (p.p_promo_name, td.t_hour)
  ),
  catalog_agg AS (
    SELECT
      p.p_promo_name        AS promo_name,
      td.t_hour             AS hour_of_day,
      SUM(cs.cs_ext_sales_price) AS catalog_sales,
      COUNT(DISTINCT cs.cs_call_center_sk) AS distinct_call_centers,
      COUNT(DISTINCT inv.inv_item_sk)      AS distinct_inventory_items,
      CASE WHEN SUM(cs.cs_ext_sales_price) > 150000 THEN 'HIGH' ELSE 'LOW' END AS sales_category
    FROM catalog_sales cs
    FULL OUTER JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p           ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim td           ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer_address ca   ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm          ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w           ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN (
      SELECT * FROM inventory TABLESAMPLE BERNOULLI (10)
    ) inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    WHERE cc.cc_country = 'USA'
      AND td.t_hour = 12
      AND cs.cs_quantity > 2
    GROUP BY CUBE (p.p_promo_name, td.t_hour)
  )
SELECT
  promo_name,
  hour_of_day,
  store_sales,
  NULL          AS web_sales,
  NULL          AS catalog_sales,
  distinct_stores,
  NULL          AS distinct_ship_modes,
  sales_category AS overall_sales_level
FROM store_agg
UNION DISTINCT
SELECT
  promo_name,
  hour_of_day,
  NULL          AS store_sales,
  web_sales,
  NULL          AS catalog_sales,
  NULL          AS distinct_stores,
  distinct_ship_modes,
  sales_category AS overall_sales_level
FROM web_agg
UNION DISTINCT
SELECT
  promo_name,
  hour_of_day,
  NULL          AS store_sales,
  NULL          AS web_sales,
  catalog_sales,
  NULL          AS distinct_stores,
  NULL          AS distinct_ship_modes,
  sales_category AS overall_sales_level
FROM catalog_agg
ORDER BY promo_name ASC, hour_of_day ASC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
