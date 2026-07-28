SELECT
    d.d_year,
    i.i_category,
    p.p_promo_name,
    w.web_state,
    ib.ib_upper_bound,
    SUM(cs.cs_net_paid) AS total_catalog_sales,
    SUM(ss.ss_net_profit) AS total_store_profit,
    SUM(ws.ws_net_profit) AS total_web_profit,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    AVG(i.i_current_price) AS avg_item_price
FROM tpcds.date_dim d
JOIN tpcds.call_center cc
  ON cc.cc_open_date_sk = d.d_date_sk
JOIN tpcds.catalog_sales cs
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN tpcds.customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN tpcds.household_demographics hd
  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN tpcds.item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN tpcds.promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN tpcds.store_sales ss
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN tpcds.store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN tpcds.web_sales ws
  ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN tpcds.web_site w
  ON ws.ws_web_site_sk = w.web_site_sk
WHERE d.d_year = 2001
  AND i.i_category = 'Electronics'
  AND hd.hd_vehicle_count > 1
  AND ib.ib_upper_bound <= 50000
  AND w.web_county = 'Jackson County'
GROUP BY
    d.d_year,
    i.i_category,
    p.p_promo_name,
    w.web_state,
    ib.ib_upper_bound
HAVING SUM(cs.cs_net_paid) > 100000
ORDER BY total_catalog_sales DESC
LIMIT 100
