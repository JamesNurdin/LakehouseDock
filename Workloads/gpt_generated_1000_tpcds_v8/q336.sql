WITH
  /* Base store_sales fact with required dimensions */
  ss_base AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_customer_sk,
      ss.ss_net_paid,
      ss.ss_quantity,
      d.d_year AS year,
      t.t_hour AS hour,
      c.c_preferred_cust_flag AS pref_flag
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2002                         -- predicate 1
      AND t.t_hour BETWEEN 9 AND 17              -- predicate 2
      AND c.c_preferred_cust_flag = 'Y'          -- predicate 3
      AND ss.ss_net_paid > 100.00                -- predicate 4
      AND ss.ss_quantity >= 1                    -- predicate 5
      AND ss.ss_wholesale_cost < 50.00           -- predicate 6
  ),

  /* Sampled inventory (fact) */
  inventory_sample AS (
    SELECT *
    FROM inventory TABLESAMPLE BERNOULLI (10)   -- TABLESAMPLE
  ),
  inventory_join AS (
    SELECT i.inv_item_sk,
           i.inv_quantity_on_hand,
           d.d_year AS year
    FROM inventory_sample i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
  ),
  inventory_agg AS (
    SELECT year,
           SUM(inv_quantity_on_hand) AS total_inventory
    FROM inventory_join
    GROUP BY year
  ),

  /* Catalog page dimension */
  catalog_page_join AS (
    SELECT cp.cp_catalog_page_id,
           cp.cp_department,
           d.d_year AS year
    FROM catalog_page cp
    JOIN date_dim d ON cp.cp_start_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
  ),
  catalog_agg AS (
    SELECT year,
           COUNT(DISTINCT cp_catalog_page_id) AS distinct_pages
    FROM catalog_page_join
    GROUP BY year
  ),

  /* Full outer join between date_dim and web_site */
  full_date_website AS (
    SELECT d.d_year AS year,
           w.web_site_id,
           w.web_name
    FROM date_dim d
    FULL OUTER JOIN web_site w ON d.d_date_sk = w.web_open_date_sk   -- FULL OUTER JOIN
    WHERE d.d_year = 2002
  ),
  website_agg AS (
    SELECT year,
           COUNT(DISTINCT web_site_id) AS distinct_web_sites
    FROM full_date_website
    GROUP BY year
  ),

  /* Web sales fact with RIGHT OUTER JOIN to ship_mode */
  ws_right AS (
    SELECT ws.ws_order_number,
           ws.ws_net_paid,
           ws.ws_quantity,
           sm.sm_ship_mode_id,
           d.d_year AS year,
           t.t_hour AS hour,
           c.c_preferred_cust_flag AS pref_flag
    FROM web_sales ws
    RIGHT OUTER JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk   -- RIGHT OUTER JOIN
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2002
      AND sm.sm_code = 'AIR'                  -- predicate 7
      AND ws.ws_net_paid > 50.00              -- predicate 8
  ),

  /* Aggregated store_sales */
  ss_agg AS (
    SELECT
      year,
      hour,
      pref_flag,
      SUM(ss_net_paid) AS total_net_paid,
      AVG(ss_quantity) AS avg_quantity,
      COUNT(DISTINCT ss_customer_sk) AS distinct_customers,
      ROW_NUMBER() OVER (PARTITION BY year ORDER BY SUM(ss_net_paid) DESC) AS rank_by_year   -- window function
    FROM ss_base
    GROUP BY year, hour, pref_flag
  ),

  /* Aggregated web_sales (right‑joined) */
  ws_agg AS (
    SELECT
      year,
      hour,
      pref_flag,
      SUM(ws_net_paid) AS total_net_paid,
      AVG(ws_quantity) AS avg_quantity,
      COUNT(DISTINCT ws_order_number) AS distinct_orders,
      ROW_NUMBER() OVER (PARTITION BY year ORDER BY SUM(ws_net_paid) DESC) AS rank_by_year   -- window function
    FROM ws_right
    GROUP BY year, hour, pref_flag
  )

/* Union of the two aggregated result sets */
SELECT
  u.year,
  u.hour,
  u.pref_flag,
  u.total_net_paid,
  u.avg_quantity,
  u.distinct_entities,
  u.rank_by_year,
  COALESCE(i.total_inventory, 0) AS total_inventory,
  COALESCE(c.distinct_pages, 0) AS distinct_pages,
  COALESCE(w.distinct_web_sites, 0) AS distinct_web_sites
FROM (
  SELECT year,
         hour,
         pref_flag,
         total_net_paid,
         avg_quantity,
         distinct_customers AS distinct_entities,
         rank_by_year
  FROM ss_agg
  UNION DISTINCT
  SELECT year,
         hour,
         pref_flag,
         total_net_paid,
         avg_quantity,
         distinct_orders AS distinct_entities,
         rank_by_year
  FROM ws_agg
) u
LEFT JOIN inventory_agg i ON u.year = i.year          -- bring in inventory information
LEFT JOIN catalog_agg c   ON u.year = c.year          -- bring in catalog page information
LEFT JOIN website_agg w   ON u.year = w.year          -- bring in web site information
ORDER BY u.year, u.rank_by_year
