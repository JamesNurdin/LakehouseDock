WITH sales_agg AS (
  SELECT
    s.s_store_id,
    i.i_item_id,
    SUM(ss.ss_net_profit) AS store_sales_profit,
    SUM(cs.cs_net_profit) AS catalog_sales_profit,
    SUM(ws.ws_net_profit) AS web_sales_profit,
    SUM(sr.sr_net_loss) AS store_returns_loss,
    SUM(wr.wr_net_loss) AS web_returns_loss
  FROM store s
  JOIN store_sales ss
    ON ss.ss_store_sk = s.s_store_sk
  JOIN date_dim d_ss
    ON ss.ss_sold_date_sk = d_ss.d_date_sk
  JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN catalog_sales cs
    ON cs.cs_bill_customer_sk = c.c_customer_sk
   AND cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   AND cs.cs_item_sk = i.i_item_sk
   AND cs.cs_ship_date_sk = d_ss.d_date_sk
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = i.i_item_sk
  LEFT JOIN date_dim d_sr
    ON sr.sr_returned_date_sk = d_sr.d_date_sk
  JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
   AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   AND ws.ws_item_sk = i.i_item_sk
   AND ws.ws_sold_date_sk = d_ss.d_date_sk
   AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   AND ws.ws_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = i.i_item_sk
  LEFT JOIN date_dim d_wr
    ON wr.wr_returned_date_sk = d_wr.d_date_sk
  WHERE
    d_ss.d_year = 2001
    AND i.i_brand_id IN (101, 202)
    AND sm.sm_type = 'AIR'
    AND w.w_state = 'CA'
    AND s.s_market_id = 5
    AND cd.cd_gender = 'F'
  GROUP BY
    s.s_store_id,
    i.i_item_id
)
SELECT
  s_store_id,
  i_item_id,
  store_sales_profit,
  catalog_sales_profit,
  web_sales_profit,
  total_profit,
  RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM (
  SELECT
    s_store_id,
    i_item_id,
    store_sales_profit,
    catalog_sales_profit,
    web_sales_profit,
    (store_sales_profit + catalog_sales_profit + web_sales_profit
     - COALESCE(store_returns_loss, 0) - COALESCE(web_returns_loss, 0)) AS total_profit
  FROM sales_agg
) t
WHERE total_profit > 0
ORDER BY total_profit DESC
LIMIT 100
