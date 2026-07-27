WITH base AS (
  SELECT
    d.d_year,
    s.s_state,
    cd.cd_gender,
    c.c_customer_id,
    cs.cs_net_paid,
    cs.cs_net_profit,
    cs.cs_list_price,
    sr.sr_net_loss,
    wr.wr_return_amt,
    ib.ib_lower_bound,
    ib.ib_upper_bound
  FROM tpcds.date_dim d
  JOIN tpcds.call_center cc
    ON cc.cc_open_date_sk = d.d_date_sk
  JOIN tpcds.catalog_sales cs
    ON cs.cs_sold_date_sk = d.d_date_sk
   AND cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN tpcds.promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN tpcds.customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN tpcds.customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
  JOIN tpcds.household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
  JOIN tpcds.income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN tpcds.store s
    ON s.s_closed_date_sk = d.d_date_sk
  JOIN tpcds.store_returns sr
    ON sr.sr_store_sk = s.s_store_sk
   AND sr.sr_returned_date_sk = d.d_date_sk
  JOIN tpcds.web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
   AND wr.wr_refunded_customer_sk = c.c_customer_sk
  JOIN tpcds.web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
  JOIN tpcds.inventory i
    ON i.inv_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND s.s_state = 'CA'
    AND p.p_discount_active = 'Y'
    AND cs.cs_list_price > 100
),
agg AS (
  SELECT
    d_year,
    s_state,
    cd_gender,
    COUNT(DISTINCT c_customer_id) AS distinct_customers,
    SUM(cs_net_paid) AS total_net_paid,
    SUM(cs_net_profit) AS total_net_profit,
    SUM(sr_net_loss) AS total_store_return_loss,
    SUM(wr_return_amt) AS total_web_return_amount,
    AVG(cs_list_price) AS avg_list_price,
    MIN(ib_lower_bound) AS min_income_lower,
    MAX(ib_upper_bound) AS max_income_upper
  FROM base
  GROUP BY d_year, s_state, cd_gender
)
SELECT
  d_year,
  s_state,
  cd_gender,
  CASE WHEN total_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category,
  distinct_customers,
  total_net_paid,
  total_store_return_loss,
  total_web_return_amount,
  avg_list_price,
  min_income_lower,
  max_income_upper
FROM agg
ORDER BY total_net_paid DESC
LIMIT 100
