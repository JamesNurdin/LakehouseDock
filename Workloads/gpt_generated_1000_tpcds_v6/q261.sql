WITH
  store_sales_union AS (
    SELECT
      d.d_year,
      CAST(NULL AS varchar) AS promo_name,
      CAST(NULL AS varchar) AS state,
      SUM(ss.ss_net_paid) AS total_amount,
      COUNT(DISTINCT ss.ss_ticket_number) AS order_count,
      CAST(0 AS decimal(7,2)) AS total_return_loss,
      CAST(0 AS integer) AS total_inventory,
      wp.wp_type AS web_page_type,
      ws.web_name AS web_site_name
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year, wp.wp_type, ws.web_name
  ),
  catalog_sales_union AS (
    SELECT
      d.d_year,
      p.p_promo_name AS promo_name,
      w.w_state AS state,
      SUM(cs.cs_net_paid) AS total_amount,
      COUNT(DISTINCT cs.cs_order_number) AS order_count,
      SUM(COALESCE(cr.cr_net_loss, 0)) AS total_return_loss,
      SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS total_inventory,
      wp.wp_type AS web_page_type,
      ws.web_name AS web_site_name
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk
     AND cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN inventory inv
      ON inv.inv_warehouse_sk = w.w_warehouse_sk
     AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
      AND p.p_discount_active = 'Y'
      AND w.w_state = 'CA'
      AND cc.cc_class = 'M'
      AND COALESCE(inv.inv_quantity_on_hand, 0) > 0
    GROUP BY d.d_year, p.p_promo_name, w.w_state, wp.wp_type, ws.web_name
  ),
  combined AS (
    SELECT * FROM store_sales_union
    UNION ALL
    SELECT * FROM catalog_sales_union
  )
SELECT
  c.d_year,
  COALESCE(c.promo_name, 'No Promo') AS promo_name,
  COALESCE(c.state, 'All States') AS state,
  SUM(c.total_amount) AS sum_total_amount,
  AVG(c.total_amount) AS avg_total_amount,
  SUM(c.order_count) AS sum_orders,
  SUM(c.total_return_loss) AS sum_return_loss,
  SUM(c.total_inventory) AS sum_inventory
FROM combined c
GROUP BY c.d_year, c.promo_name, c.state
HAVING SUM(c.total_amount) > 10000
ORDER BY c.d_year ASC, sum_total_amount DESC
LIMIT 100
