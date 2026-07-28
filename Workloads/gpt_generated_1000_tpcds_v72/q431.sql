WITH sales_base AS (
   SELECT
       c.c_customer_sk,
       c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       i.i_item_id,
       i.i_category,
       d.d_year,
       d.d_date,
       w.w_warehouse_name,
       s.s_store_name,
       we.web_site_id,
       cs.cs_net_paid_inc_tax,
       cs.cs_order_number,
       ib.ib_lower_bound,
       ib.ib_upper_bound
   FROM catalog_sales cs
   JOIN date_dim d                     ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN time_dim t                     ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN customer c                    ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd     ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   LEFT JOIN income_band ib           ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN item i                        ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p                   ON cs.cs_promo_sk = p.p_promo_sk
   JOIN call_center cc                ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp               ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm                  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w                   ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN store s                       ON s.s_closed_date_sk = d.d_date_sk
   JOIN catalog_returns cr            ON cr.cr_order_number = cs.cs_order_number
   JOIN reason r                      ON cr.cr_reason_sk = r.r_reason_sk
   JOIN web_sales ws                  ON ws.ws_order_number = cs.cs_order_number
   JOIN web_page wp                   ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN web_site we                   ON ws.ws_web_site_sk = we.web_site_sk
   JOIN web_returns wr                ON wr.wr_order_number = ws.ws_order_number
   LEFT JOIN store_returns sr         ON sr.sr_customer_sk = c.c_customer_sk
   WHERE d.d_year = 2001
     AND i.i_category = 'Sports'
     AND p.p_discount_active = 'Y'
     AND cs.cs_net_paid_inc_tax > 1000
     AND w.w_county = 'Richland County'
     AND we.web_mkt_id IN (1, 2, 3)
),
filtered_sales AS (
   SELECT *
   FROM sales_base sb
   WHERE NOT EXISTS (
       SELECT 1 FROM store_returns sr2
       WHERE sr2.sr_customer_sk = sb.c_customer_sk
   )
)
SELECT
   c_customer_id,
   c_first_name,
   c_last_name,
   i_item_id,
   i_category,
   d_year,
   w_warehouse_name,
   s_store_name,
   web_site_id,
   total_sales,
   cumulative_sales,
   yearly_sales_rank,
   CASE
       WHEN ib_lower_bound IS NULL THEN 'No Income Band'
       ELSE concat('Band ', CAST(ib_lower_bound AS varchar), '-', CAST(ib_upper_bound AS varchar))
   END AS income_band_desc
FROM (
   SELECT
       c_customer_id,
       c_first_name,
       c_last_name,
       i_item_id,
       i_category,
       d_year,
       w_warehouse_name,
       s_store_name,
       web_site_id,
       ib_lower_bound,
       ib_upper_bound,
       d_date,
       SUM(cs_net_paid_inc_tax) AS total_sales,
       SUM(SUM(cs_net_paid_inc_tax)) OVER (
           PARTITION BY c_customer_sk
           ORDER BY d_date
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS cumulative_sales,
       RANK() OVER (
           PARTITION BY d_year
           ORDER BY SUM(cs_net_paid_inc_tax) DESC
       ) AS yearly_sales_rank
   FROM filtered_sales
   GROUP BY
       c_customer_id,
       c_first_name,
       c_last_name,
       i_item_id,
       i_category,
       d_year,
       w_warehouse_name,
       s_store_name,
       web_site_id,
       ib_lower_bound,
       ib_upper_bound,
       c_customer_sk,
       d_date
) t
ORDER BY yearly_sales_rank, total_sales DESC
LIMIT 100
