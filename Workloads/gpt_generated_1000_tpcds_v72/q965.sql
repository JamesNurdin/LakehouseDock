WITH sales_agg AS (
        SELECT i.i_item_sk,
               i.i_item_id,
               i.i_product_name,
               COALESCE(SUM(cs.cs_net_profit), 0) AS catalog_profit,
               COALESCE(SUM(ss.ss_net_profit), 0) AS store_profit,
               COALESCE(SUM(ws.ws_net_profit), 0) AS web_profit,
               COALESCE(SUM(cs.cs_net_profit), 0) + COALESCE(SUM(ss.ss_net_profit), 0) + COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit
        FROM item i
        LEFT JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
        LEFT JOIN store_sales   ss ON ss.ss_item_sk = i.i_item_sk
        LEFT JOIN web_sales     ws ON ws.ws_item_sk = i.i_item_sk
        GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name
),
ranked_sales AS (
        SELECT i_item_sk,
               i_item_id,
               i_product_name,
               catalog_profit,
               store_profit,
               web_profit,
               total_profit,
               RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
        FROM sales_agg
)
SELECT d.d_year,
       i.i_item_id,
       i.i_product_name,
       rs.catalog_profit,
       rs.store_profit,
       rs.web_profit,
       rs.total_profit,
       rs.profit_rank,
       cc.cc_name,
       s.s_store_name,
       sm.sm_type,
       ib.ib_lower_bound,
       r_sr.r_reason_desc   AS store_return_reason,
       r_cr.r_reason_desc   AS catalog_return_reason
FROM   ranked_sales rs
JOIN   item i               ON i.i_item_sk = rs.i_item_sk
JOIN   inventory inv        ON inv.inv_item_sk = i.i_item_sk
JOIN   date_dim d           ON inv.inv_date_sk = d.d_date_sk
JOIN   store s              ON s.s_closed_date_sk = d.d_date_sk
JOIN   call_center cc       ON cc.cc_closed_date_sk = d.d_date_sk
JOIN   catalog_page cp      ON cp.cp_end_date_sk = d.d_date_sk
JOIN   web_page wp          ON wp.wp_creation_date_sk = d.d_date_sk
JOIN   store_sales ss       ON ss.ss_sold_date_sk = d.d_date_sk AND ss.ss_item_sk = i.i_item_sk
JOIN   catalog_sales cs     ON cs.cs_sold_date_sk = d.d_date_sk AND cs.cs_item_sk = i.i_item_sk
JOIN   web_sales ws         ON ws.ws_sold_date_sk = d.d_date_sk AND ws.ws_item_sk = i.i_item_sk
JOIN   store_returns sr     ON sr.sr_returned_date_sk = d.d_date_sk AND sr.sr_item_sk = i.i_item_sk
JOIN   catalog_returns cr   ON cr.cr_returned_date_sk = d.d_date_sk AND cr.cr_item_sk = i.i_item_sk
JOIN   reason r_sr          ON r_sr.r_reason_sk = sr.sr_reason_sk
JOIN   reason r_cr          ON r_cr.r_reason_sk = cr.cr_reason_sk
JOIN   ship_mode sm         ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
JOIN   customer c           ON c.c_customer_sk = ss.ss_customer_sk
JOIN   customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
JOIN   household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
JOIN   income_band ib       ON ib.ib_income_band_sk = hd.hd_income_band_sk
WHERE  d.d_year = 2001
  AND  cc.cc_hours = '8AM-4PM'
  AND  ib.ib_upper_bound > 50000
ORDER BY rs.profit_rank
LIMIT 100
