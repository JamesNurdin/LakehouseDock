WITH high_income AS (
   SELECT ib_income_band_sk
   FROM income_band
   WHERE ib_lower_bound >= 100000
)
SELECT
   d.d_year,
   s.s_store_name,
   r.r_reason_desc,
   SUM(ss.ss_net_profit)                     AS store_sales_profit,
   SUM(cs.cs_net_paid)                       AS catalog_sales_paid,
   SUM(ws.ws_net_paid)                       AS web_sales_paid,
   SUM(sr.sr_net_loss)                       AS store_returns_loss,
   SUM(cr.cr_net_loss)                       AS catalog_returns_loss,
   SUM(wr.wr_net_loss)                       AS web_returns_loss,
   (SELECT COUNT(DISTINCT ca2.ca_city) FROM customer_address ca2) AS distinct_cities,
   (SELECT COUNT(*) FROM inventory)                                          AS total_inventory_records
FROM
   store_sales ss
   JOIN date_dim d        ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN time_dim t        ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN customer c        ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd   ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN customer_address ca       ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN store s                   ON ss.ss_store_sk = s.s_store_sk
   JOIN promotion p               ON ss.ss_promo_sk = p.p_promo_sk
   JOIN inventory i               ON i.inv_date_sk = d.d_date_sk
   JOIN warehouse w               ON i.inv_warehouse_sk = w.w_warehouse_sk
   JOIN catalog_sales cs          ON cs.cs_sold_date_sk = d.d_date_sk
                                   AND cs.cs_sold_time_sk = t.t_time_sk
   JOIN catalog_page cp           ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN call_center cc            ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN warehouse w2              ON cs.cs_warehouse_sk = w2.w_warehouse_sk
   JOIN promotion p2              ON cs.cs_promo_sk = p2.p_promo_sk
   JOIN catalog_returns cr        ON cr.cr_order_number = cs.cs_order_number
                                   AND cr.cr_returned_date_sk = d.d_date_sk
   JOIN web_sales ws              ON ws.ws_sold_date_sk = d.d_date_sk
                                   AND ws.ws_sold_time_sk = t.t_time_sk
   JOIN web_site we               ON ws.ws_web_site_sk = we.web_site_sk
   JOIN web_returns wr            ON wr.wr_order_number = ws.ws_order_number
                                   AND wr.wr_returned_date_sk = d.d_date_sk
   JOIN store_returns sr          ON sr.sr_ticket_number = ss.ss_ticket_number
                                   AND sr.sr_returned_date_sk = d.d_date_sk
   JOIN reason r                  ON r.r_reason_sk = sr.sr_reason_sk
   LEFT JOIN reason r2            ON r2.r_reason_sk = cr.cr_reason_sk
   LEFT JOIN reason r3            ON r3.r_reason_sk = wr.wr_reason_sk
   JOIN high_income hi            ON hd.hd_income_band_sk = hi.ib_income_band_sk
WHERE
   d.d_year BETWEEN 2000 AND 2002
GROUP BY GROUPING SETS (
   (d.d_year, s.s_store_name, r.r_reason_desc),
   (d.d_year, s.s_store_name),
   (d.d_year),
   ()
)
ORDER BY d.d_year, s.s_store_name
LIMIT 100
