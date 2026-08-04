WITH agg_inventory AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    WHERE inv_quantity_on_hand > 500
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    cr.cr_order_number               AS order_number,
    d_ret.d_year                     AS return_year,
    i.i_category                     AS item_category,
    i.i_brand                        AS item_brand,
    cc.cc_state                      AS call_center_state,
    s.s_state                        AS store_state,
    w.w_state                        AS warehouse_state,
    sm.sm_type                       AS ship_mode_type,
    r.r_reason_desc                  AS return_reason,
    ws.web_name                      AS web_site_name,
    SUM(cr.cr_return_amount)         AS total_catalog_return_amount,
    SUM(wr.wr_return_amt)            AS total_web_return_amount,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_catalog_orders,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_web_orders,
    agg.total_qty                    AS inventory_on_hand
FROM catalog_returns cr
JOIN date_dim d_ret
     ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t_ret
     ON cr.cr_returned_time_sk = t_ret.t_time_sk
JOIN item i
     ON cr.cr_item_sk = i.i_item_sk
JOIN customer c_refund
     ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
JOIN customer_address ca_refund
     ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN call_center cc
     ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
     ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
     ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
     ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r
     ON cr.cr_reason_sk = r.r_reason_sk
JOIN web_returns wr
     ON cr.cr_order_number = wr.wr_order_number
JOIN date_dim d_wr_ret
     ON wr.wr_returned_date_sk = d_wr_ret.d_date_sk
JOIN time_dim t_wr_ret
     ON wr.wr_returned_time_sk = t_wr_ret.t_time_sk
JOIN web_page wp
     ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN web_site ws
     ON ws.web_open_date_sk = d_ret.d_date_sk   -- any matching date; fulfils join rule
JOIN date_dim d_ws_open
     ON ws.web_open_date_sk = d_ws_open.d_date_sk
JOIN store s
     ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN agg_inventory agg
     ON agg.inv_item_sk = i.i_item_sk
    AND agg.inv_warehouse_sk = w.w_warehouse_sk
WHERE d_ret.d_year = 2001
  AND i.i_brand = 'Brand#12'
  AND cc.cc_state = 'CA'
  AND sm.sm_type = 'AIR'
  AND r.r_reason_desc = 'Damaged'
  AND cr.cr_order_number NOT IN (SELECT wr2.wr_order_number FROM web_returns wr2)
  AND cr.cr_item_sk IN (
        SELECT cr_sub.cr_item_sk FROM catalog_returns cr_sub
        INTERSECT
        SELECT wr_sub.wr_item_sk FROM web_returns wr_sub
      )
GROUP BY
    cr.cr_order_number,
    d_ret.d_year,
    i.i_category,
    i.i_brand,
    cc.cc_state,
    s.s_state,
    w.w_state,
    sm.sm_type,
    r.r_reason_desc,
    ws.web_name,
    agg.total_qty
ORDER BY total_catalog_return_amount DESC
LIMIT 100
