WITH base AS (
   SELECT
      cs.cs_order_number,
      cs.cs_sold_date_sk,
      cs.cs_net_paid_inc_tax,
      cs.cs_ext_sales_price,
      cs.cs_ext_discount_amt,
      cs.cs_item_sk,
      cs.cs_quantity,
      c.c_customer_id,
      c.c_first_name,
      c.c_last_name,
      w.w_warehouse_id,
      w.w_county,
      r.r_reason_id,
      r.r_reason_desc,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      i.inv_quantity_on_hand,
      ws.ws_net_paid,
      ws.ws_quantity,
      wp.wp_url,
      wp.wp_type,
      RANK() OVER (PARTITION BY w.w_warehouse_id ORDER BY cs.cs_net_paid_inc_tax DESC) AS warehouse_sales_rank,
      CASE WHEN cs.cs_net_paid_inc_tax > 5000 THEN 'HIGH' ELSE 'NORMAL' END AS sales_category
   FROM catalog_sales cs
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
   JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
       AND ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   WHERE r.r_reason_id IN ('AAAAAAAACBAAAAAA','AAAAAAAABAAAAAAA')
     AND w.w_county = 'Franklin Parish'
     AND cs.cs_net_paid_inc_tax > 1000
     AND ws.ws_net_paid > 500
     AND EXISTS (
         SELECT 1 FROM inventory i2
         WHERE i2.inv_item_sk = cs.cs_item_sk
           AND i2.inv_warehouse_sk = w.w_warehouse_sk
           AND i2.inv_quantity_on_hand > 0
     )
)
SELECT
    base.cs_order_number,
    base.c_customer_id,
    base.c_first_name,
    base.c_last_name,
    base.w_warehouse_id,
    base.w_county,
    base.r_reason_id,
    base.r_reason_desc,
    base.cs_net_paid_inc_tax,
    base.sales_category,
    base.warehouse_sales_rank,
    COUNT(DISTINCT base.r_reason_id) OVER (PARTITION BY base.w_warehouse_id) AS distinct_reason_cnt,
    SUM(DISTINCT base.cs_ext_discount_amt) OVER (PARTITION BY base.w_warehouse_id) AS sum_distinct_discount
FROM base
ORDER BY base.cs_net_paid_inc_tax DESC, base.warehouse_sales_rank
LIMIT 100
