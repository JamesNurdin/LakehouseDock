WITH
  sales_data AS (
    SELECT
      cp.cp_department AS cp_department,
      i.i_category AS i_category,
      p.p_promo_name AS p_promo_name,
      w.w_state AS w_state,
      sm.sm_type AS sm_type,
      c_bill.c_birth_country AS c_birth_country,
      SUM(cs.cs_net_paid) AS total_paid,
      COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    GROUP BY
      cp.cp_department,
      i.i_category,
      p.p_promo_name,
      w.w_state,
      sm.sm_type,
      c_bill.c_birth_country
  ),
  returns_data AS (
    SELECT
      cp.cp_department AS cp_department,
      i.i_category AS i_category,
      r.r_reason_desc AS r_reason_desc,
      w.w_state AS w_state,
      sm.sm_type AS sm_type,
      c_ref.c_birth_country AS c_birth_country,
      SUM(cr.cr_net_loss) AS total_loss,
      COUNT(DISTINCT cr.cr_order_number) AS return_cnt
    FROM catalog_returns cr
    JOIN catalog_sales cs
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c_ref ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
    JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    GROUP BY
      cp.cp_department,
      i.i_category,
      r.r_reason_desc,
      w.w_state,
      sm.sm_type,
      c_ref.c_birth_country
  ),
  store_inventory AS (
    SELECT
      wp.wp_type AS wp_type,
      i.i_category AS i_category,
      p.p_promo_name AS p_promo_name,
      w.w_state AS w_state,
      c.c_birth_country AS c_birth_country,
      SUM(ss.ss_net_paid) AS store_sales,
      SUM(inv.inv_quantity_on_hand) AS on_hand_qty
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    GROUP BY
      wp.wp_type,
      i.i_category,
      p.p_promo_name,
      w.w_state,
      c.c_birth_country
  ),
  combined AS (
    SELECT
      cp_department AS department,
      i_category AS category,
      'sales'    AS metric_type,
      total_paid AS amount,
      order_cnt  AS cnt,
      w_state    AS state,
      sm_type    AS ship_mode,
      c_birth_country AS country
    FROM sales_data
    UNION ALL
    SELECT
      cp_department,
      i_category,
      'return'   AS metric_type,
      total_loss AS amount,
      return_cnt AS cnt,
      w_state    AS state,
      sm_type    AS ship_mode,
      c_birth_country AS country
    FROM returns_data
  )
SELECT DISTINCT
  comb.department,
  comb.category,
  comb.metric_type,
  comb.amount,
  comb.cnt,
  comb.state,
  comb.ship_mode,
  comb.country,
  si.store_sales,
  si.on_hand_qty,
  ROW_NUMBER() OVER (PARTITION BY comb.department ORDER BY comb.amount DESC) AS dept_rank
FROM combined comb
JOIN store_inventory si
  ON comb.category = si.i_category
 AND comb.state    = si.w_state
 AND comb.country  = si.c_birth_country
ORDER BY comb.amount DESC
LIMIT 100
