WITH customer_sales AS (
   SELECT
       c.c_customer_sk,
       c.c_customer_id,
       ca.ca_city,
       w.w_warehouse_name,
       SUM(cs.cs_net_profit)      AS cat_profit,
       SUM(ss.ss_net_profit)      AS store_profit,
       SUM(ws.ws_net_profit)      AS web_profit,
       SUM(sr.sr_net_loss)        AS store_loss,
       SUM(wr.wr_net_loss)        AS web_loss
   FROM
       time_dim t
   JOIN catalog_sales cs          ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN catalog_page cp           ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN warehouse w               ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN store_sales ss            ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN store_returns sr          ON sr.sr_return_time_sk = t.t_time_sk
                                 AND sr.sr_ticket_number = ss.ss_ticket_number
   JOIN web_sales ws              ON ws.ws_sold_time_sk = t.t_time_sk
   JOIN web_returns wr            ON wr.wr_returned_time_sk = t.t_time_sk
                                 AND wr.wr_order_number = ws.ws_order_number
   JOIN web_page wp               ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN web_site wsite            ON ws.ws_web_site_sk = wsite.web_site_sk
   JOIN customer c                ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_address ca       ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd  ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib            ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE
       t.t_hour IN (8, 12, 15)
       AND w.w_state = 'CA'
       AND ca.ca_country = 'United States'
       AND cp.cp_department = 'Shoes'
       AND ib.ib_upper_bound >= 50000
   GROUP BY
       c.c_customer_sk,
       c.c_customer_id,
       ca.ca_city,
       w.w_warehouse_name
),
avg_profit AS (
   SELECT AVG(total_net) AS avg_total
   FROM (
       SELECT (cat_profit + store_profit + web_profit - store_loss - web_loss) AS total_net
       FROM customer_sales
   )
)
SELECT
   cs.c_customer_id,
   cs.ca_city,
   cs.w_warehouse_name,
   (cs.cat_profit + cs.store_profit + cs.web_profit - cs.store_loss - cs.web_loss) AS total_net_profit,
   ROW_NUMBER() OVER (ORDER BY (cs.cat_profit + cs.store_profit + cs.web_profit - cs.store_loss - cs.web_loss) DESC) AS profit_rank,
   CASE
       WHEN (cs.cat_profit + cs.store_profit + cs.web_profit - cs.store_loss - cs.web_loss) > (SELECT avg_total FROM avg_profit)
       THEN 'Above Avg'
       ELSE 'Below Avg'
   END AS profit_category
FROM customer_sales cs
ORDER BY profit_rank
LIMIT 100
