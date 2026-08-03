WITH
  /* Aggregate sales per order and item */
  sales_agg AS (
    SELECT
      cs_order_number,
      cs_item_sk,
      cs_bill_customer_sk,
      cs_sold_date_sk,
      cs_sold_time_sk,
      cs_call_center_sk,
      cs_catalog_page_sk,
      cs_warehouse_sk,
      cs_promo_sk,
      SUM(cs_quantity)               AS total_qty,
      SUM(cs_net_paid)               AS total_paid,
      SUM(cs_net_profit)             AS total_profit
    FROM catalog_sales
    GROUP BY
      cs_order_number,
      cs_item_sk,
      cs_bill_customer_sk,
      cs_sold_date_sk,
      cs_sold_time_sk,
      cs_call_center_sk,
      cs_catalog_page_sk,
      cs_warehouse_sk,
      cs_promo_sk
  ),

  /* Aggregate inventory per item‑warehouse */
  inventory_agg AS (
    SELECT
      inv_item_sk,
      inv_warehouse_sk,
      SUM(inv_quantity_on_hand) AS stock_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
  ),

  /* First set of filters (filter set A) */
  prep_a AS (
    SELECT
      sa.cs_order_number,
      i.i_item_id,
      i.i_category,
      i.i_brand,
      p.p_promo_name,
      c.c_first_name,
      c.c_last_name,
      ca.ca_city,
      cc.cc_state,
      cp.cp_department,
      td.t_hour,
      w.w_warehouse_name,
      wp.wp_url,
      sa.total_qty,
      sa.total_paid,
      sa.total_profit,
      ia.stock_on_hand,
      COALESCE(cr.cr_return_quantity, 0)     AS catalog_return_qty,
      COALESCE(wr.wr_return_quantity, 0)     AS web_return_qty,
      metric_value,
      metric_type
    FROM sales_agg sa
    JOIN item i               ON sa.cs_item_sk = i.i_item_sk
    JOIN promotion p          ON sa.cs_promo_sk = p.p_promo_sk
    JOIN customer c           ON sa.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca  ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN call_center cc       ON sa.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp      ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td          ON sa.cs_sold_time_sk = td.t_time_sk
    JOIN warehouse w          ON sa.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory_agg ia ON ia.inv_item_sk = i.i_item_sk AND ia.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = sa.cs_order_number AND cr.cr_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr      ON wr.wr_item_sk = i.i_item_sk AND wr.wr_order_number = sa.cs_order_number
    LEFT JOIN web_page wp          ON wr.wr_web_page_sk = wp.wp_web_page_sk
    /* explode an array of two metrics */
    CROSS JOIN UNNEST(ARRAY[sa.total_qty, sa.total_paid]) AS u(metric_value)
    CROSS JOIN UNNEST(ARRAY['quantity', 'paid']) AS v(metric_type)
    WHERE cc.cc_state = 'CA'
      AND cp.cp_department = 'Sports'
      AND i.i_brand = 'Brand#12'
      AND p.p_discount_active = 'Y'
      AND ca.ca_state = 'TX'
      AND cc.cc_rec_start_date >= DATE '2000-01-01'
  ),

  /* Second set of filters (filter set B) */
  prep_b AS (
    SELECT
      sa.cs_order_number,
      i.i_item_id,
      i.i_category,
      i.i_brand,
      p.p_promo_name,
      c.c_first_name,
      c.c_last_name,
      ca.ca_city,
      cc.cc_state,
      cp.cp_department,
      td.t_hour,
      w.w_warehouse_name,
      wp.wp_url,
      sa.total_qty,
      sa.total_paid,
      sa.total_profit,
      ia.stock_on_hand,
      COALESCE(cr.cr_return_quantity, 0)     AS catalog_return_qty,
      COALESCE(wr.wr_return_quantity, 0)     AS web_return_qty,
      metric_value,
      metric_type
    FROM sales_agg sa
    JOIN item i               ON sa.cs_item_sk = i.i_item_sk
    JOIN promotion p          ON sa.cs_promo_sk = p.p_promo_sk
    JOIN customer c           ON sa.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca  ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN call_center cc       ON sa.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp      ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td          ON sa.cs_sold_time_sk = td.t_time_sk
    JOIN warehouse w          ON sa.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory_agg ia ON ia.inv_item_sk = i.i_item_sk AND ia.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = sa.cs_order_number AND cr.cr_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr      ON wr.wr_item_sk = i.i_item_sk AND wr.wr_order_number = sa.cs_order_number
    LEFT JOIN web_page wp          ON wr.wr_web_page_sk = wp.wp_web_page_sk
    CROSS JOIN UNNEST(ARRAY[sa.total_qty, sa.total_paid]) AS u(metric_value)
    CROSS JOIN UNNEST(ARRAY['quantity', 'paid']) AS v(metric_type)
    WHERE cc.cc_state = 'NY'
      AND cp.cp_department = 'Books'
      AND i.i_brand = 'Brand#34'
      AND p.p_discount_active = 'N'
      AND ca.ca_state = 'FL'
      AND cc.cc_rec_start_date >= DATE '1999-01-01'
  ),

  /* Union the two prepared sets */
  unioned AS (
    SELECT * FROM prep_a
    UNION DISTINCT
    SELECT * FROM prep_b
  )

SELECT
  i_item_id,
  i_category,
  i_brand,
  p_promo_name,
  MAX(wp_url)                               AS sample_url,
  SUM(total_qty)                            AS sum_qty,
  SUM(total_paid)                           AS sum_paid,
  SUM(total_profit)                         AS sum_profit,
  AVG(stock_on_hand)                        AS avg_stock_on_hand,
  COUNT(DISTINCT cs_order_number)           AS distinct_orders,
  SUM(CASE WHEN metric_type = 'quantity' THEN metric_value ELSE 0 END) AS metric_qty_total,
  SUM(CASE WHEN metric_type = 'paid' THEN metric_value ELSE 0 END)      AS metric_paid_total,
  /* scalar sub‑query */
  (SELECT MAX(w_warehouse_sq_ft) FROM warehouse) AS max_warehouse_sq_ft
FROM unioned
GROUP BY
  i_item_id,
  i_category,
  i_brand,
  p_promo_name
ORDER BY
  sum_paid DESC
LIMIT 100
