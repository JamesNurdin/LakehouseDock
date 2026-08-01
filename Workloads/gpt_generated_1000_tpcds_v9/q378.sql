WITH base AS (
   SELECT
      cr.cr_return_quantity,
      cr.cr_return_amount,
      cr.cr_order_number,
      cp.cp_catalog_page_id,
      cp.cp_department,
      cp.cp_catalog_number,
      r.r_reason_desc,
      r.r_reason_sk,
      sm.sm_type,
      w.w_warehouse_name,
      w.w_state,
      d_ret.d_year AS ret_year,
      d_sold.d_year AS sold_year,
      ws.ws_order_number,
      ws.ws_quantity,
      ws.ws_ext_sales_price,
      p.p_promo_id,
      p.p_channel_dmail
   FROM catalog_returns cr
   JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
   JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
   JOIN web_sales ws ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
                    AND ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
   JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
   WHERE d_ret.d_year = 2001
     AND d_sold.d_year = 2001
     AND cp.cp_department = 'Sports'
     AND r.r_reason_desc LIKE '%price%'
     AND p.p_channel_dmail = 'Y'
     AND w.w_state = 'CA'
),
returns_agg AS (
   SELECT
      'return' AS record_type,
      cp_catalog_page_id,
      p_promo_id,
      w_warehouse_name,
      sm_type,
      r_reason_desc,
      r_reason_sk,
      SUM(cr_return_amount) AS amount,
      COUNT(DISTINCT cr_order_number) AS orders,
      SUM(cr_return_quantity) AS quantity
   FROM base
   GROUP BY cp_catalog_page_id, p_promo_id, w_warehouse_name, sm_type, r_reason_desc, r_reason_sk
),
sales_agg AS (
   SELECT
      'sale' AS record_type,
      cp_catalog_page_id,
      p_promo_id,
      w_warehouse_name,
      sm_type,
      r_reason_desc,
      r_reason_sk,
      SUM(ws_ext_sales_price) AS amount,
      COUNT(DISTINCT ws_order_number) AS orders,
      SUM(ws_quantity) AS quantity
   FROM base
   GROUP BY cp_catalog_page_id, p_promo_id, w_warehouse_name, sm_type, r_reason_desc, r_reason_sk
),
combined AS (
   SELECT * FROM returns_agg
   UNION ALL
   SELECT * FROM sales_agg
)
SELECT
   record_type,
   cp_catalog_page_id,
   p_promo_id,
   w_warehouse_name,
   sm_type,
   r_reason_desc,
   amount,
   orders,
   quantity,
   RANK() OVER (PARTITION BY w_warehouse_name ORDER BY amount DESC) AS amount_rank,
   SUM(amount) OVER (PARTITION BY w_warehouse_name) AS warehouse_total_amount
FROM combined
WHERE NOT EXISTS (
   SELECT 1 FROM reason r2
   WHERE r2.r_reason_sk = combined.r_reason_sk
     AND r2.r_reason_desc LIKE '%duplicate%'
)
ORDER BY w_warehouse_name, amount_rank
