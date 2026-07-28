WITH
store_data AS (
   SELECT
     s.s_store_id,
     d.d_year AS d_year,
     SUM(ss.ss_net_profit) AS store_sales_profit,
     SUM(sr.sr_net_loss) AS store_return_loss
   FROM store_sales ss
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cdemo ON ss.ss_cdemo_sk = cdemo.cd_demo_sk
   JOIN household_demographics hdemo ON ss.ss_hdemo_sk = hdemo.hd_demo_sk
   JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
   JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   WHERE t.t_hour BETWEEN 9 AND 17
   GROUP BY s.s_store_id, d.d_year
),
catalog_data AS (
   SELECT
     cc.cc_call_center_id,
     d.d_year AS d_year,
     SUM(cs.cs_net_paid) AS catalog_sales_net,
     SUM(cr.cr_net_loss) AS catalog_return_loss,
     COUNT(DISTINCT cs.cs_order_number) AS catalog_orders
   FROM catalog_sales cs
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cdemo ON cs.cs_bill_cdemo_sk = cdemo.cd_demo_sk
   JOIN household_demographics hdemo ON cs.cs_bill_hdemo_sk = hdemo.hd_demo_sk
   JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   WHERE p.p_discount_active = 'Y'
     AND cp.cp_type = 'Electronic'
     AND w.w_state = 'WA'
   GROUP BY cc.cc_call_center_id, d.d_year
),
web_data AS (
   SELECT
     wp.wp_web_page_id,
     d.d_year AS d_year,
     SUM(wr.wr_net_loss) AS web_return_loss,
     COUNT(*) AS web_returns_cnt
   FROM web_returns wr
   JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
   GROUP BY wp.wp_web_page_id, d.d_year
)
SELECT
   sd.s_store_id,
   sd.d_year,
   sd.store_sales_profit,
   sd.store_return_loss,
   cd.catalog_sales_net,
   cd.catalog_return_loss,
   wd.web_return_loss,
   CASE
     WHEN cd.catalog_sales_net > 0 THEN cd.catalog_sales_net - cd.catalog_return_loss
     ELSE 0
   END AS net_catalog,
   (sd.store_sales_profit - sd.store_return_loss)
     + CASE WHEN cd.catalog_sales_net > 0 THEN cd.catalog_sales_net - cd.catalog_return_loss ELSE 0 END
     - wd.web_return_loss AS total_net
FROM store_data sd
LEFT JOIN catalog_data cd ON cd.d_year = sd.d_year
LEFT JOIN web_data wd ON wd.d_year = sd.d_year
WHERE
   sd.d_year = 1999
   AND sd.s_store_id IN (SELECT s2.s_store_id FROM store s2 WHERE s2.s_state = 'CA')
   AND EXISTS (
       SELECT 1 FROM web_returns wr2
       JOIN reason r2 ON wr2.wr_reason_sk = r2.r_reason_sk
       WHERE r2.r_reason_desc LIKE '%damaged%'
         AND wr2.wr_return_amt > 200
   )
   AND EXISTS (
       SELECT 1 FROM promotion p2
       WHERE p2.p_discount_active = 'Y'
         AND p2.p_start_date_sk = (
               SELECT d3.d_date_sk FROM date_dim d3 WHERE d3.d_date = DATE '1999-01-01'
         )
   )
GROUP BY
   sd.s_store_id,
   sd.d_year,
   sd.store_sales_profit,
   sd.store_return_loss,
   cd.catalog_sales_net,
   cd.catalog_return_loss,
   wd.web_return_loss
HAVING
   (sd.store_sales_profit - sd.store_return_loss)
     + CASE WHEN cd.catalog_sales_net > 0 THEN cd.catalog_sales_net - cd.catalog_return_loss ELSE 0 END
     - wd.web_return_loss > 1000
ORDER BY total_net DESC
LIMIT 100
