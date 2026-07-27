WITH latest_inventory AS (
        SELECT inv_item_sk, MAX(inv_date_sk) AS max_date_sk
        FROM inventory
        GROUP BY inv_item_sk
    ),
    inventory_latest AS (
        SELECT i.i_item_sk,
               i.i_category,
               i.i_brand,
               inv.inv_quantity_on_hand
        FROM latest_inventory li
        JOIN inventory inv ON inv.inv_item_sk = li.inv_item_sk AND inv.inv_date_sk = li.max_date_sk
        JOIN item i ON i.i_item_sk = inv.inv_item_sk
    ),
    returns AS (
        SELECT cr.cr_item_sk,
               cr.cr_return_amount,
               cr.cr_return_tax,
               cr.cr_fee,
               cr.cr_return_ship_cost,
               cr.cr_net_loss,
               cr.cr_returned_date_sk,
               cr.cr_returned_time_sk,
               cr.cr_ship_mode_sk,
               cr.cr_reason_sk,
               cr.cr_call_center_sk,
               cr.cr_catalog_page_sk,
               cr.cr_refunded_customer_sk,
               cr.cr_refunded_addr_sk
        FROM catalog_returns cr
        UNION ALL
        SELECT wr.wr_item_sk          AS cr_item_sk,
               wr.wr_return_amt      AS cr_return_amount,
               wr.wr_return_tax      AS cr_return_tax,
               wr.wr_fee             AS cr_fee,
               wr.wr_return_ship_cost AS cr_return_ship_cost,
               wr.wr_net_loss        AS cr_net_loss,
               wr.wr_returned_date_sk AS cr_returned_date_sk,
               wr.wr_returned_time_sk AS cr_returned_time_sk,
               NULL                  AS cr_ship_mode_sk,
               wr.wr_reason_sk       AS cr_reason_sk,
               NULL                  AS cr_call_center_sk,
               NULL                  AS cr_catalog_page_sk,
               wr.wr_refunded_customer_sk AS cr_refunded_customer_sk,
               wr.wr_refunded_addr_sk      AS cr_refunded_addr_sk
        FROM web_returns wr
    )
SELECT
    i.i_category,
    sm.sm_type            AS ship_mode_type,
    r.r_reason_desc,
    d_ret.d_year,
    ws.web_name,
    COUNT(*)              AS total_returns,
    SUM(ret.cr_return_amount) AS total_return_amount,
    SUM(ret.cr_net_loss)      AS total_net_loss,
    SUM(COALESCE(inv_latest.inv_quantity_on_hand, 0)) AS latest_inventory_on_hand
FROM returns ret
JOIN item i               ON ret.cr_item_sk = i.i_item_sk
LEFT JOIN ship_mode sm    ON ret.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN reason r        ON ret.cr_reason_sk = r.r_reason_sk
JOIN date_dim d_ret       ON ret.cr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t_ret       ON ret.cr_returned_time_sk = t_ret.t_time_sk
LEFT JOIN customer c_ref ON ret.cr_refunded_customer_sk = c_ref.c_customer_sk
LEFT JOIN customer_address ca_ref ON ret.cr_refunded_addr_sk = ca_ref.ca_address_sk
LEFT JOIN call_center cc  ON ret.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN catalog_page cp ON ret.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN inventory_latest inv_latest ON i.i_item_sk = inv_latest.i_item_sk
LEFT JOIN web_site ws       ON ws.web_open_date_sk = d_ret.d_date_sk
WHERE EXISTS (
        SELECT 1
        FROM store s
        JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
        WHERE s.s_state = 'CA' AND d_store.d_year = d_ret.d_year
    )
  AND d_ret.d_year BETWEEN 2000 AND 2002
GROUP BY i.i_category, sm.sm_type, r.r_reason_desc, d_ret.d_year, ws.web_name
ORDER BY total_net_loss DESC
LIMIT 100
