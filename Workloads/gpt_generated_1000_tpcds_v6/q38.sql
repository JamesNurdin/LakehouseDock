WITH sales_agg AS (
  SELECT
    cc.cc_name,
    s.s_store_name,
    d_sold.d_year,
    cd_bill.cd_gender,
    SUM(ws.ws_net_paid_inc_ship_tax) AS total_net_paid,
    AVG(ws.ws_quantity) AS avg_quantity,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_ext_tax) AS total_tax
  FROM tpcds.web_sales ws
  JOIN tpcds.date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
  JOIN tpcds.date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
  JOIN tpcds.customer c_bill
    ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
  JOIN tpcds.customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN tpcds.household_demographics hd_bill
    ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN tpcds.income_band ib
    ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
  JOIN tpcds.call_center cc
    ON cc.cc_closed_date_sk = d_sold.d_date_sk
  JOIN tpcds.store s
    ON s.s_closed_date_sk = d_ship.d_date_sk
  WHERE
    d_sold.d_quarter_seq = 15
    AND d_ship.d_week_seq = 20
    AND cc.cc_state = 'CA'
    AND s.s_state = 'TX'
    AND hd_bill.hd_buy_potential = '>10000'
    AND ib.ib_lower_bound >= 50000
    AND ws.ws_net_paid_inc_ship_tax > 1000
    AND cd_bill.cd_gender = 'F'
    AND ws.ws_quantity BETWEEN 2 AND 5
  GROUP BY
    cc.cc_name,
    s.s_store_name,
    d_sold.d_year,
    cd_bill.cd_gender
)
SELECT
  cc_name,
  s_store_name,
  d_year,
  cd_gender,
  total_net_paid,
  avg_quantity,
  order_cnt,
  total_tax,
  RANK() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS yearly_net_rank
FROM sales_agg
ORDER BY d_year DESC, total_net_paid DESC
LIMIT 100
