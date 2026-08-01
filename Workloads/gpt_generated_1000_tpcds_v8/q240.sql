WITH
  -- Base join that includes all selected tables
  base AS (
    SELECT
      cs.cs_order_number,
      cs.cs_net_paid,
      cs.cs_net_profit,
      cs.cs_quantity,
      cr.cr_net_loss,
      wr.wr_net_loss,
      d.d_year,
      d.d_date_sk,
      cp.cp_department,
      p.p_promo_id,
      c.c_customer_id,
      ca.ca_state,
      i.inv_quantity_on_hand,
      ss.ss_quantity AS ss_quantity,
      ws.ws_net_paid,
      ws.ws_net_profit,
      wp.wp_url,
      wsite.web_name,
      t.t_hour
    FROM catalog_sales cs
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t
      ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_sales ss
      ON ss.ss_sold_date_sk = d.d_date_sk
     AND ss.ss_customer_sk = c.c_customer_sk
     AND ss.ss_addr_sk = ca.ca_address_sk
    JOIN inventory i
      ON i.inv_date_sk = d.d_date_sk
    JOIN web_sales ws
      ON ws.ws_sold_date_sk = d.d_date_sk
     AND ws.ws_bill_customer_sk = c.c_customer_sk
     AND ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite
      ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE d.d_year = 2001
      AND p.p_discount_active = 'Y'
      AND cp.cp_department = 'Electronics'
      AND c.c_birth_country = 'United States'
      AND wp.wp_type = 'homepage'
  ),

  -- Key sets for set operations
  catalog_keys AS (
    SELECT cs.cs_order_number
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
  ),
  web_keys AS (
    SELECT ws.ws_order_number
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
  ),
  intersect_keys AS (
    SELECT cs_order_number FROM catalog_keys INTERSECT SELECT ws_order_number FROM web_keys
  ),
  except_keys AS (
    SELECT cs_order_number FROM catalog_keys EXCEPT SELECT ws_order_number FROM web_keys
  ),

  -- Aggregation per year / department
  agg AS (
    SELECT
      d_year,
      cp_department,
      COUNT(DISTINCT cs_order_number) AS num_orders,
      SUM(cs_net_paid) AS total_catalog_sales,
      AVG(ws_net_paid) AS avg_web_sales,
      MAX(cr_net_loss) AS max_catalog_return_loss,
      MIN(wr_net_loss) AS min_web_return_loss,
      (SELECT COUNT(*) FROM intersect_keys) AS intersect_order_cnt,
      (SELECT COUNT(*) FROM except_keys)   AS except_order_cnt
    FROM base
    GROUP BY d_year, cp_department
  )
SELECT
  d_year,
  cp_department,
  num_orders,
  total_catalog_sales,
  avg_web_sales,
  max_catalog_return_loss,
  min_web_return_loss,
  ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_catalog_sales DESC) AS sales_rank,
  intersect_order_cnt,
  except_order_cnt
FROM agg
ORDER BY total_catalog_sales DESC
LIMIT 100
