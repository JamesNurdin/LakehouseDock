WITH
  -- Store sales chain joining all related tables
  store_data AS (
    SELECT
      d.d_year,
      i.i_category,
      ss.ss_customer_sk,
      ss.ss_quantity,
      ss.ss_net_paid,
      ss.ss_net_profit,
      cd.cd_education_status,
      p.p_promo_name,
      w.w_city,
      inv.inv_quantity_on_hand
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                      AND inv.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 17
      AND i.i_brand = 'Brand#12'
      AND p.p_discount_active = 'Y'
      AND cd.cd_education_status = 'College'
      AND w.w_city = 'Los Angeles'
  ),

  -- Web sales chain joining all related tables
  web_data AS (
    SELECT
      d.d_year,
      i.i_category,
      ws.ws_bill_customer_sk AS customer_sk,
      ws.ws_quantity,
      ws.ws_net_paid,
      ws.ws_net_profit,
      cd.cd_education_status,
      p.p_promo_name,
      w.w_city,
      sm.sm_type,
      wp.wp_type,
      we.web_country,
      inv.inv_quantity_on_hand
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                      AND inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND sm.sm_type = 'AIR'
      AND we.web_country = 'United States'
      AND wp.wp_type = 'HOME'
      AND i.i_color = 'Red'
  ),

  -- Full outer join of warehouse and inventory (keeps unmatched rows from both sides)
  wh_inv_full AS (
    SELECT
      w.w_warehouse_sk,
      w.w_city,
      inv.inv_quantity_on_hand
    FROM warehouse w
    FULL OUTER JOIN inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
  ),

  -- Anti‑join: customers that never appear in web_returns
  cust_no_return AS (
    SELECT c.c_customer_sk
    FROM customer c
    WHERE NOT EXISTS (
      SELECT 1 FROM web_returns wr WHERE wr.wr_refunded_customer_sk = c.c_customer_sk
    )
  ),

  -- Reason table used in a simple predicate (ensures the table participates)
  reason_usage AS (
    SELECT r.r_reason_desc
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%service%'
  ),

  -- Key sets for set operations
  key_set_a AS (SELECT DISTINCT ss_customer_sk AS cust_sk FROM store_data),
  key_set_b AS (SELECT DISTINCT customer_sk AS cust_sk FROM web_data),

  key_except AS (SELECT cust_sk FROM key_set_a EXCEPT SELECT cust_sk FROM key_set_b),
  key_intersect AS (SELECT cust_sk FROM key_set_a INTERSECT SELECT cust_sk FROM key_set_b),

  -- Union of store and web data (DISTINCT) followed by aggregation
  union_agg AS (
    SELECT
      d_year,
      i_category,
      city,
      SUM(total_sales) AS total_sales,
      AVG(avg_sales) AS avg_sales,
      COUNT(DISTINCT customer_sk) AS distinct_customers,
      MAX(customer_sk) AS customer_sk,
      CASE WHEN SUM(total_sales) > 50000 THEN 'HIGH' ELSE 'LOW' END AS sales_tier
    FROM (
      SELECT
        d_year,
        i_category,
        w_city AS city,
        ss_net_paid AS total_sales,
        ss_net_paid AS avg_sales,
        ss_customer_sk AS customer_sk
      FROM store_data
      WHERE ss_quantity > 5
      UNION DISTINCT
      SELECT
        d_year,
        i_category,
        w_city AS city,
        ws_net_paid AS total_sales,
        ws_net_paid AS avg_sales,
        customer_sk
      FROM web_data
      WHERE ws_quantity > 5
    ) u
    GROUP BY d_year, i_category, city
  )

SELECT
  ua.d_year,
  ua.i_category,
  ua.city,
  ua.total_sales,
  ua.avg_sales,
  ua.distinct_customers,
  ua.sales_tier,
  whif.inv_quantity_on_hand,
  CASE WHEN ua.customer_sk IN (SELECT cust_sk FROM key_except) THEN 'IN_EXCEPT' ELSE 'NOT_IN_EXCEPT' END AS except_flag,
  CASE WHEN ua.customer_sk IN (SELECT cust_sk FROM key_intersect) THEN 'IN_INTERSECT' ELSE 'NOT_IN_INTERSECT' END AS intersect_flag,
  CASE WHEN ua.customer_sk IN (SELECT c_customer_sk FROM cust_no_return) THEN 'NO_RETURN' ELSE 'HAS_RETURN' END AS return_flag
FROM union_agg ua
LEFT JOIN wh_inv_full whif ON ua.city = whif.w_city
ORDER BY ua.total_sales DESC
LIMIT 100
