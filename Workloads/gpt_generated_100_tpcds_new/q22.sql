WITH base AS (
  SELECT
    ws.ws_order_number,
    ws.ws_net_profit,
    ws.ws_net_paid,
    ws.ws_quantity,
    sr.sr_return_amt,
    wr.wr_return_amt AS web_return_amt,
    sr.sr_store_sk,
    sr.sr_returned_date_sk,
    d_sold.d_year AS sold_year,
    d_ship.d_year AS ship_year,
    -- dimensions joined for completeness
    i.i_item_id,
    i.i_category,
    i.i_brand,
    c_bill.c_customer_id,
    ca_bill.ca_state,
    sm.sm_type,
    ws_site.web_name,
    cc.cc_call_center_id,
    cp.cp_catalog_page_id
  FROM web_sales ws
  JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
  JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
  JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
  JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN income_band ib_bill ON hd_bill.hd_income_band_sk = ib_bill.ib_income_band_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
  LEFT JOIN web_returns wr
    ON ws.ws_item_sk = wr.wr_item_sk
   AND ws.ws_order_number = wr.wr_order_number
  LEFT JOIN date_dim d_wr_return ON wr.wr_returned_date_sk = d_wr_return.d_date_sk
  LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
  LEFT JOIN store_returns sr ON i.i_item_sk = sr.sr_item_sk
  LEFT JOIN date_dim d_sr_return ON sr.sr_returned_date_sk = d_sr_return.d_date_sk
  LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
  LEFT JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
  LEFT JOIN income_band ib_sr ON hd_sr.hd_income_band_sk = ib_sr.ib_income_band_sk
  LEFT JOIN call_center cc ON cc.cc_open_date_sk = d_sold.d_date_sk
  LEFT JOIN catalog_page cp ON cp.cp_start_date_sk = d_sold.d_date_sk
  WHERE d_sold.d_year = 2001
),
agg AS (
  SELECT
    s.s_store_id,
    d_sr_return.d_year AS return_year,
    d_sr_return.d_month_seq AS return_month,
    SUM(base.ws_net_profit) AS total_net_profit,
    SUM(base.sr_return_amt) AS total_store_return_amt,
    SUM(base.web_return_amt) AS total_web_return_amt,
    COUNT(DISTINCT base.ws_order_number) AS order_cnt
  FROM base
  JOIN store s ON base.sr_store_sk = s.s_store_sk
  JOIN date_dim d_sr_return ON base.sr_returned_date_sk = d_sr_return.d_date_sk
  GROUP BY s.s_store_id, d_sr_return.d_year, d_sr_return.d_month_seq
)
SELECT *
FROM (
  SELECT
    agg.*,
    ROW_NUMBER() OVER (PARTITION BY agg.return_year ORDER BY agg.total_net_profit DESC) AS rn
  FROM agg
) ranked
WHERE rn <= 5
ORDER BY return_year, total_net_profit DESC
LIMIT 100
