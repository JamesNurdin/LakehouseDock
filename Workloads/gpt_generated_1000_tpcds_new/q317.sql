WITH base AS (
   SELECT
       d.d_date AS d_date,
       cs.cs_order_number,
       cs.cs_quantity,
       ws.ws_quantity,
       cs.cs_net_profit,
       cr.cr_net_loss,
       wr.wr_net_loss,
       sr.sr_net_loss,
       CASE WHEN cs.cs_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
       ARRAY[cs.cs_quantity, ws.ws_quantity] AS qty_array
   FROM tpcds.date_dim d
   INNER JOIN tpcds.store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
   INNER JOIN tpcds.time_dim t ON sr.sr_return_time_sk = t.t_time_sk
   INNER JOIN tpcds.customer c ON sr.sr_customer_sk = c.c_customer_sk
   INNER JOIN tpcds.customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
   INNER JOIN tpcds.household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
   INNER JOIN tpcds.store s ON sr.sr_store_sk = s.s_store_sk
   INNER JOIN tpcds.catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
   INNER JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   INNER JOIN tpcds.catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
   INNER JOIN tpcds.web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
   INNER JOIN tpcds.web_returns wr ON wr.wr_order_number = ws.ws_order_number
   INNER JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   INNER JOIN tpcds.web_site we ON ws.ws_web_site_sk = we.web_site_sk
   INNER JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
     AND w.w_zip = '56098'
     AND cd.cd_gender = 'M'
     AND ib.ib_upper_bound >= 40000
     AND s.s_state = 'CA'
     AND t.t_hour BETWEEN 9 AND 17
     AND cs.cs_quantity > 0
)
SELECT
    d_date,
    profit_flag,
    SUM(cs_net_profit) AS total_profit,
    SUM(cr_net_loss) AS total_cr_loss,
    SUM(wr_net_loss) AS total_wr_loss,
    SUM(sr_net_loss) AS total_sr_loss,
    COUNT(*) AS txn_count,
    qty_val
FROM base
CROSS JOIN UNNEST(qty_array) AS t(qty_val)
GROUP BY d_date, profit_flag, qty_val
HAVING SUM(cs_net_profit) > 1000
ORDER BY total_profit DESC
LIMIT 100
