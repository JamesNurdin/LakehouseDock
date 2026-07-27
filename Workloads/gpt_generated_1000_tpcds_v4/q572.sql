WITH inv_agg AS (
    SELECT
        inv_warehouse_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_warehouse_sk, inv_date_sk
)
SELECT
    d.d_year,
    w.w_warehouse_name,
    sm.sm_type,
    cp.cp_department,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    inv_agg.total_qty,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_web_orders
FROM catalog_returns cr
JOIN date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t
  ON cr.cr_returned_time_sk = t.t_time_sk
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN customer_address ca_refund
  ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN customer_address ca_return
  ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
JOIN inv_agg
  ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
 AND inv_agg.inv_date_sk = d.d_date_sk
JOIN web_returns wr
  ON wr.wr_returned_date_sk = d.d_date_sk
 AND wr.wr_returned_time_sk = t.t_time_sk
JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN store s
  ON s.s_closed_date_sk = d.d_date_sk
JOIN web_site ws
  ON ws.web_open_date_sk = d.d_date_sk
JOIN promotion p
  ON p.p_start_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND sm.sm_code = 'AIR'
  AND p.p_end_date_sk >= d.d_date_sk
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_id = p.p_promo_id
          AND p2.p_discount_active = 'Y'
    )
GROUP BY
    d.d_year,
    w.w_warehouse_name,
    sm.sm_type,
    cp.cp_department,
    inv_agg.total_qty
ORDER BY total_return_amount DESC
LIMIT 100
