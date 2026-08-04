WITH
  store_agg AS (
    SELECT
      d.d_year,
      i.i_category,
      s.s_store_name,
      SUM(ss.ss_net_paid) AS total_net_paid,
      COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND i.i_category_id IN (2, 3, 6)
      AND s.s_state = 'CA'
      AND cd.cd_gender = 'M'
      AND ss.ss_net_paid > 1000
    GROUP BY CUBE (d.d_year, i.i_category, s.s_store_name)
  ),
  catalog_agg AS (
    SELECT
      d.d_year,
      cp.cp_department,
      cc.cc_market_manager,
      sm.sm_code,
      SUM(cs.cs_net_paid) AS total_net_paid,
      COUNT(*) AS orders_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
      AND cp.cp_department = 'DEPARTMENT'
      AND cc.cc_market_manager LIKE '%Damico%'
      AND sm.sm_code = 'AIR'
      AND i.i_category_id = 9
    GROUP BY CUBE (d.d_year, cp.cp_department, cc.cc_market_manager, sm.sm_code)
  ),
  web_agg AS (
    SELECT
      d.d_year,
      wp.wp_type,
      sm.sm_code AS ship_mode,
      SUM(ws.ws_net_paid) AS total_net_paid,
      COUNT(*) AS web_orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
      AND wp.wp_type = 'A'
      AND sm.sm_code = 'AIR'
      AND i.i_category_id = 9
    GROUP BY CUBE (d.d_year, wp.wp_type, sm.sm_code)
  ),
  intersect_years AS (
    SELECT d_year FROM store_agg
    INTERSECT
    SELECT d_year FROM catalog_agg
  ),
  full_join AS (
    SELECT
      COALESCE(sa.d_year, ca.d_year, wa.d_year) AS year,
      sa.total_net_paid AS store_net,
      ca.total_net_paid AS catalog_net,
      wa.total_net_paid AS web_net,
      sa.sales_cnt,
      ca.orders_cnt,
      wa.web_orders
    FROM store_agg sa
    FULL OUTER JOIN catalog_agg ca ON sa.d_year = ca.d_year
    FULL OUTER JOIN web_agg wa ON COALESCE(sa.d_year, ca.d_year) = wa.d_year
  )
SELECT
  fj.year,
  SUM(fj.store_net) AS sum_store_net,
  SUM(fj.catalog_net) AS sum_catalog_net,
  SUM(fj.web_net) AS sum_web_net,
  COUNT(*) AS row_cnt
FROM full_join fj
WHERE fj.year IN (SELECT d_year FROM intersect_years)
  AND EXISTS (
        SELECT 1
        FROM inventory inv
        JOIN date_dim d2 ON inv.inv_date_sk = d2.d_date_sk
        WHERE d2.d_year = fj.year
          AND inv.inv_quantity_on_hand > 0
      )
GROUP BY CUBE (fj.year)
HAVING SUM(fj.store_net) > 5000
ORDER BY sum_store_net DESC
LIMIT 100
