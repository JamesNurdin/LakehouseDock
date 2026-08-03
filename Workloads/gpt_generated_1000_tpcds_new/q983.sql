WITH
  sales_agg AS (
    SELECT
      d.d_year,
      sm.sm_ship_mode_id,
      cd.cd_gender,
      t.t_hour,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      COUNT(*) AS sales_cnt,
      AVG(cs.cs_net_profit) AS avg_profit
    FROM catalog_sales cs
    JOIN date_dim d               ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t               ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm             ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w              ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p              ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c               ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib           ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND sm.sm_code IN ('AIR', 'SEA')
      AND w.w_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND cd.cd_gender = 'M'
      AND t.t_hour BETWEEN 8 AND 20
      AND ib.ib_lower_bound >= 20000
      AND EXISTS (
        SELECT 1 FROM promotion p2
        WHERE p2.p_promo_sk = cs.cs_promo_sk
          AND p2.p_discount_active = 'Y'
      )
    GROUP BY d.d_year, sm.sm_ship_mode_id, cd.cd_gender, t.t_hour
  ),

  returns_agg AS (
    SELECT
      d.d_year,
      r.r_reason_desc,
      COUNT(*) AS return_cnt,
      SUM(sr.sr_return_amt) AS total_returns
    FROM store_returns sr
    JOIN date_dim d               ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r                 ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer c               ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca      ON sr.sr_addr_sk = ca.ca_address_sk
    LEFT JOIN web_page wp         ON wp.wp_customer_sk = c.c_customer_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND c.c_preferred_cust_flag = 'Y'
      AND ca.ca_country = 'United States'
      AND r.r_reason_desc LIKE '%Damaged%'
      AND wp.wp_type = 'article'
      AND EXISTS (
        SELECT 1 FROM web_site ws
        WHERE ws.web_open_date_sk = d.d_date_sk
          AND ws.web_country = 'United States'
      )
    GROUP BY d.d_year, r.r_reason_desc
  ),

  union_data AS (
    SELECT d_year,
           sm_ship_mode_id AS category,
           total_sales        AS metric_value
    FROM sales_agg
    UNION DISTINCT
    SELECT d_year,
           r_reason_desc AS category,
           total_returns  AS metric_value
    FROM returns_agg
  ),

  full_inv AS (
    SELECT
      d.d_year,
      w.w_warehouse_name,
      inv.inv_quantity_on_hand
    FROM inventory inv
    FULL OUTER JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d          ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND w.w_country = 'United States'
      AND inv.inv_quantity_on_hand > 0
  )
SELECT
  ud.d_year,
  ud.category,
  SUM(ud.metric_value)               AS total_metric,
  COALESCE(SUM(fi.inv_quantity_on_hand), 0) AS total_inventory
FROM union_data ud
LEFT JOIN full_inv fi ON ud.d_year = fi.d_year
GROUP BY ud.d_year, ud.category
HAVING SUM(ud.metric_value) > 1000
ORDER BY ud.d_year DESC, total_metric DESC
OFFSET 0 LIMIT 100
