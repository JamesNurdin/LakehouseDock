WITH profit_avg AS (
   SELECT AVG(cr.cr_net_loss) AS avg_loss
   FROM catalog_returns cr
   WHERE cr.cr_return_amount > 100
)
SELECT
   cp.cp_catalog_number,
   w.w_state,
   d.d_year,
   SUM(cs.cs_net_paid) AS total_sales,
   AVG(cs.cs_net_profit) AS avg_profit,
   COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
   MAX(cs.cs_net_paid_inc_tax) AS max_net_paid_inc_tax,
   MIN(cs.cs_ext_discount_amt) AS min_discount,
   profit_avg.avg_loss
FROM
   date_dim d
   INNER JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
   INNER JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   INNER JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
   INNER JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   INNER JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   INNER JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   INNER JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   INNER JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   INNER JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   INNER JOIN store s ON s.s_closed_date_sk = d.d_date_sk
   INNER JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
   INNER JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk AND ws.ws_warehouse_sk = w.w_warehouse_sk
   INNER JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   INNER JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_web_page_sk = wp.wp_web_page_sk
   INNER JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
   CROSS JOIN profit_avg
WHERE
   d.d_year = 2001
   AND cp.cp_department = 'Electronics'
   AND w.w_state = 'CA'
   AND cs.cs_net_profit > profit_avg.avg_loss
GROUP BY
   cp.cp_catalog_number,
   w.w_state,
   d.d_year,
   profit_avg.avg_loss
ORDER BY
   total_sales DESC
LIMIT 100
