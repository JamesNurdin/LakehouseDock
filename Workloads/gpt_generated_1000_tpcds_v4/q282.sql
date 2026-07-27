WITH base AS (
  SELECT
    ss.ss_ext_sales_price      AS ss_sales,
    ss.ss_net_profit           AS ss_profit,
    ws.ws_ext_sales_price      AS ws_sales,
    ws.ws_net_profit           AS ws_profit,
    wr.wr_net_loss             AS return_loss,
    cp.cp_catalog_page_id,
    c.c_customer_id,
    ca.ca_state,
    d.d_year,
    hd.hd_income_band_sk,
    sm.sm_code,
    s.s_store_name,
    s.s_state
  FROM store_sales ss
  JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN web_sales ws
    ON ss.ss_item_sk = ws.ws_item_sk
   AND ss.ss_ticket_number = ws.ws_order_number
  JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
   AND ws.ws_item_sk = wr.wr_item_sk
  JOIN catalog_page cp
    ON d.d_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
  WHERE d.d_year = 2001
    AND sm.sm_code = 'AIR'
    AND c.c_birth_country = 'CHILE'
)
SELECT
  base.s_store_name,
  base.sm_code,
  base.d_year,
  SUM(base.ss_sales)       AS store_sales_total,
  SUM(base.ws_sales)       AS web_sales_total,
  SUM(base.return_loss)    AS total_return_loss,
  AVG(base.ss_profit)      AS avg_store_net_profit
FROM base
GROUP BY base.s_store_name, base.sm_code, base.d_year
HAVING SUM(base.ss_sales) > 100000
ORDER BY store_sales_total DESC
LIMIT 10
