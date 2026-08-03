WITH enriched AS (
   SELECT
      cr.cr_order_number,
      cr.cr_return_amount,
      cr.cr_net_loss,
      cr.cr_return_quantity,
      cc.cc_name,
      cc.cc_state,
      sm.sm_type,
      i.i_item_id,
      i.i_product_name,
      i.i_current_price,
      p.p_promo_name,
      r.r_reason_desc,
      t.t_hour,
      w.w_state,
      wp.wp_url,
      wp.wp_autogen_flag
   FROM catalog_returns cr
   JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   LEFT JOIN promotion p ON i.i_item_sk = p.p_item_sk
   JOIN customer c_ret ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
   LEFT JOIN web_page wp ON wp.wp_customer_sk = c_ret.c_customer_sk
   JOIN customer c_ref ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
   JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
   JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
   JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
   JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
   JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
   JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   WHERE cc.cc_employees > 1000000
     AND sm.sm_type = 'EXPRESS'
     AND i.i_current_price BETWEEN 10 AND 500
     AND t.t_hour BETWEEN 9 AND 17
     AND w.w_state = 'CA'
     AND wp.wp_autogen_flag = 'N'
),
high_loss AS (
   SELECT cr_order_number
   FROM catalog_returns
   WHERE cr_net_loss > 5000
),
large_qty AS (
   SELECT cr_order_number
   FROM catalog_returns
   WHERE cr_return_quantity > 20
),
diff_keys AS (
   SELECT cr_order_number FROM high_loss
   EXCEPT
   SELECT cr_order_number FROM large_qty
),
intersect_keys AS (
   SELECT cr_order_number FROM high_loss
   INTERSECT
   SELECT cr_order_number FROM catalog_returns WHERE cr_return_amount > 1000
),
ranked AS (
   SELECT
      e.cr_order_number,
      e.cc_name,
      e.r_reason_desc,
      e.i_product_name,
      e.cr_return_amount,
      CASE WHEN e.cr_return_amount > 1000 THEN 'High' ELSE 'Normal' END AS amount_category,
      SUM(e.cr_net_loss) OVER (PARTITION BY e.cc_name ORDER BY e.cr_return_amount DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_net_loss,
      ROW_NUMBER() OVER (PARTITION BY e.cc_name ORDER BY e.cr_return_amount DESC) AS rn
   FROM enriched e
   WHERE e.cr_order_number IN (SELECT cr_order_number FROM diff_keys)
     AND e.cr_order_number IN (SELECT cr_order_number FROM intersect_keys)
)
SELECT
   cr_order_number,
   cc_name,
   r_reason_desc,
   i_product_name,
   cr_return_amount,
   amount_category,
   cum_net_loss,
   rn
FROM ranked
WHERE rn <= 5
ORDER BY cc_name, rn
LIMIT 100
