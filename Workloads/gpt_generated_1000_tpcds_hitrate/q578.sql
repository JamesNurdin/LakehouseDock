WITH base AS (
  SELECT
    c.c_customer_sk,
    c.c_customer_id,
    d.d_year,
    d.d_month_seq,
    t.t_hour,
    ss.ss_net_profit               AS store_net_profit,
    ws.ws_net_profit               AS web_net_profit,
    sr.sr_net_loss                 AS store_return_loss,
    wr.wr_net_loss                 AS web_return_loss,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd.hd_buy_potential,
    w.w_warehouse_name,
    wsit.web_name
  FROM tpcds.date_dim d
  JOIN tpcds.store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN tpcds.time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN tpcds.store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_returned_date_sk = d.d_date_sk
  JOIN tpcds.customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN tpcds.customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN tpcds.customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN tpcds.household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN tpcds.income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN tpcds.web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
   AND ws.ws_sold_date_sk = d.d_date_sk
  JOIN tpcds.warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN tpcds.web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_returned_date_sk = d.d_date_sk
  JOIN tpcds.web_site wsit
    ON ws.ws_web_site_sk = wsit.web_site_sk
   AND wsit.web_open_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND ca.ca_country = 'United States'
    AND hd.hd_buy_potential = '5001-10000'
    AND ib.ib_lower_bound >= 30000
    AND ss.ss_list_price > 50
    AND ws.ws_net_paid_inc_tax > 100
)
SELECT
  customer_id,
  d_year,
  hd_buy_potential,
  w_warehouse_name,
  web_name,
  SUM(store_net_profit)   AS total_store_profit,
  SUM(web_net_profit)     AS total_web_profit,
  SUM(store_return_loss)  AS total_store_loss,
  SUM(web_return_loss)    AS total_web_loss,
  SUM(total_returns)      AS total_returns
FROM (
  SELECT
    b.c_customer_id          AS customer_id,
    b.d_year,
    b.hd_buy_potential,
    b.w_warehouse_name,
    b.web_name,
    b.store_net_profit,
    b.web_net_profit,
    b.store_return_loss,
    b.web_return_loss,
    lt.total_returns
  FROM base b
  LEFT JOIN LATERAL (
    SELECT SUM(sr2.sr_return_quantity) AS total_returns
    FROM tpcds.store_returns sr2
    WHERE sr2.sr_customer_sk = b.c_customer_sk
  ) lt ON true
  WHERE b.c_customer_sk NOT IN (
    SELECT sr3.sr_customer_sk
    FROM tpcds.store_returns sr3
    WHERE sr3.sr_net_loss > 1000
  )
  AND b.c_customer_sk IN (
    SELECT c2.c_customer_sk
    FROM tpcds.customer c2
    EXCEPT
    SELECT wr2.wr_refunded_customer_sk
    FROM tpcds.web_returns wr2
  )
) sub
GROUP BY GROUPING SETS (
  (customer_id, d_year, hd_buy_potential),
  (w_warehouse_name, web_name)
)
ORDER BY total_store_profit DESC
LIMIT 100
