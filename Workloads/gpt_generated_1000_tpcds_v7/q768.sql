SELECT
    d.d_date,
    cc.cc_name,
    s.s_store_name,
    c.c_customer_id,
    cd.cd_gender,
    hd.hd_income_band_sk,
    ss.ss_net_profit,
    SUM(ss.ss_net_profit) OVER (PARTITION BY s.s_store_sk ORDER BY d.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit,
    RANK() OVER (PARTITION BY s.s_store_sk ORDER BY ss.ss_net_profit DESC) AS profit_rank,
    CASE 
        WHEN ss.ss_net_profit > 1000 THEN 'HIGH'
        WHEN ss.ss_net_profit > 0 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category
FROM tpcds.date_dim d
JOIN tpcds.call_center cc
  ON cc.cc_closed_date_sk = d.d_date_sk
JOIN tpcds.store s
  ON s.s_closed_date_sk = d.d_date_sk
JOIN tpcds.store_sales ss
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN tpcds.time_dim t
  ON ss.ss_sold_time_sk = t.t_time_sk
JOIN tpcds.customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN tpcds.customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
JOIN tpcds.customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.web_page wp
  ON wp.wp_customer_sk = c.c_customer_sk
JOIN tpcds.web_site ws
  ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND cc.cc_state = 'CA'
  AND s.s_state = 'WA'
  AND c.c_preferred_cust_flag = 'Y'
  AND t.t_hour BETWEEN 9 AND 17
ORDER BY d.d_date, profit_rank
LIMIT 100
