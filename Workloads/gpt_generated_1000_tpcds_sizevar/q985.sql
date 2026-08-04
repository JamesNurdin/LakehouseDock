WITH inv_agg AS (
   SELECT inv_warehouse_sk,
          inv_date_sk,
          SUM(inv_quantity_on_hand) AS total_qty
   FROM inventory
   GROUP BY inv_warehouse_sk, inv_date_sk
)
SELECT
   d_cr.d_year                                     AS return_year,
   w.w_state                                      AS warehouse_state,
   cd_returning.cd_gender                         AS gender,
   COUNT(DISTINCT cust_returning.c_customer_id)   AS distinct_returning_customers,
   SUM(DISTINCT cr.cr_return_amount)              AS sum_distinct_return_amount,
   SUM(cr.cr_net_loss)                            AS total_net_loss,
   SUM(CASE WHEN cr.cr_return_amount > (
           SELECT AVG(cr2.cr_return_amount)
           FROM catalog_returns cr2)
        THEN cr.cr_return_amount ELSE 0 END)    AS high_return_amount_sum,
   SUM(inv_agg.total_qty)                         AS total_inventory_qty,
   MAX(CASE WHEN inv_agg.total_qty > (
           SELECT AVG(t.total_qty)
           FROM (SELECT SUM(inv_quantity_on_hand) AS total_qty
                 FROM inventory
                 GROUP BY inv_warehouse_sk) t)
        THEN 1 ELSE 0 END)                       AS inventory_above_avg_flag
FROM catalog_returns cr
JOIN date_dim d_cr
  ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN customer cust_returning
  ON cr.cr_returning_customer_sk = cust_returning.c_customer_sk
JOIN customer_demographics cd_returning
  ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN household_demographics hd_returning
  ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN customer_address ca_returning
  ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN inv_agg
  ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
 AND inv_agg.inv_date_sk = d_cr.d_date_sk
-- store_returns side
JOIN store_returns sr
  ON sr.sr_ticket_number = cr.cr_order_number
JOIN date_dim d_sr
  ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN reason r_sr
  ON sr.sr_reason_sk = r_sr.r_reason_sk
-- store_sales side
JOIN store_sales ss
  ON ss.ss_ticket_number = sr.sr_ticket_number
 AND ss.ss_item_sk = sr.sr_item_sk
JOIN date_dim d_ss
  ON ss.ss_sold_date_sk = d_ss.d_date_sk
JOIN customer cust_ss
  ON ss.ss_customer_sk = cust_ss.c_customer_sk
JOIN customer_demographics cd_ss
  ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
JOIN household_demographics hd_ss
  ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN customer_address ca_ss
  ON ss.ss_addr_sk = ca_ss.ca_address_sk
-- web_page side
JOIN web_page wp
  ON wp.wp_customer_sk = cust_returning.c_customer_sk
JOIN date_dim d_wp_create
  ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
JOIN date_dim d_wp_access
  ON wp.wp_access_date_sk = d_wp_access.d_date_sk
-- web_site side
JOIN web_site ws
  ON ws.web_open_date_sk = d_wp_create.d_date_sk
JOIN date_dim d_ws_close
  ON ws.web_close_date_sk = d_ws_close.d_date_sk
WHERE d_cr.d_year BETWEEN 1999 AND 2000
GROUP BY GROUPING SETS (
   (d_cr.d_year, w.w_state, cd_returning.cd_gender),
   (d_cr.d_year, w.w_state),
   (cd_returning.cd_gender),
   ()
)
ORDER BY return_year DESC,
         warehouse_state,
         distinct_returning_customers DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
