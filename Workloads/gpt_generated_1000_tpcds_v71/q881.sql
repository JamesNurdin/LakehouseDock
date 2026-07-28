WITH base_sales AS (
  SELECT
    d.d_year,
    st.s_state,
    cs.cs_order_number,
    cs.cs_sales_price,
    cs.cs_net_profit,
    cs.cs_quantity,
    ca.ca_state,
    hd.hd_vehicle_count,
    hd.hd_buy_potential,
    r.r_reason_desc,
    sr.sr_return_amt,
    we.web_site_id,
    inv.inv_quantity_on_hand,
    cc.cc_city,
    cp.cp_department,
    sm.sm_type
  FROM date_dim d
  JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer cust
    ON cs.cs_bill_customer_sk = cust.c_customer_sk
  JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN store_sales ss
    ON ss.ss_customer_sk = cust.c_customer_sk
    AND ss.ss_sold_date_sk = d.d_date_sk
  LEFT JOIN store st
    ON ss.ss_store_sk = st.s_store_sk
  LEFT JOIN store_returns sr
    ON sr.sr_customer_sk = cust.c_customer_sk
    AND sr.sr_returned_date_sk = d.d_date_sk
    AND sr.sr_ticket_number = ss.ss_ticket_number
  LEFT JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
  LEFT JOIN web_sales ws
    ON ws.ws_bill_customer_sk = cust.c_customer_sk
    AND ws.ws_sold_date_sk = d.d_date_sk
  LEFT JOIN web_site we
    ON ws.ws_web_site_sk = we.web_site_sk
  LEFT JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
  WHERE d.d_year = 2002
    AND ca.ca_state = 'CA'
    AND hd.hd_buy_potential = '1001-5000'
    AND cc.cc_city = 'River'
)
SELECT
  d_year,
  s_state,
  CASE
    WHEN SUM(cs_net_profit) > 100000 THEN 'High Profit'
    WHEN SUM(cs_net_profit) > 0 THEN 'Medium Profit'
    ELSE 'Low Profit'
  END AS profit_category,
  COUNT(DISTINCT cs_order_number) AS distinct_orders,
  SUM(cs_sales_price) AS total_sales,
  AVG(cs_sales_price) AS avg_sales,
  SUM(CASE WHEN r_reason_desc IS NOT NULL THEN sr_return_amt ELSE 0 END) AS total_return_amount,
  (SELECT SUM(cs_net_profit)
     FROM catalog_sales
    WHERE cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2002)) AS year_total_profit
FROM base_sales
GROUP BY ROLLUP (d_year, s_state)
HAVING SUM(cs_sales_price) > 1000
ORDER BY d_year DESC, s_state, profit_category
LIMIT 100
