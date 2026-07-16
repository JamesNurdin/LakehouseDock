WITH store_agg AS (
  SELECT
    t.t_hour AS hour_of_day,
    c.c_preferred_cust_flag AS pref_flag,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(ss.ss_net_paid_inc_tax) AS store_net_paid_inc_tax,
    SUM(ss.ss_ext_discount_amt) AS store_discount,
    COUNT(*) AS store_txn_count
  FROM store_sales ss
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  WHERE ss.ss_sold_date_sk BETWEEN 2450800 AND 2451100
    AND c.c_preferred_cust_flag = 'Y'
  GROUP BY t.t_hour, c.c_preferred_cust_flag
),
web_agg AS (
  SELECT
    t.t_hour AS hour_of_day,
    c.c_preferred_cust_flag AS pref_flag,
    SUM(ws.ws_net_profit) AS web_net_profit,
    SUM(ws.ws_net_paid_inc_tax) AS web_net_paid_inc_tax,
    SUM(ws.ws_ext_discount_amt) AS web_discount,
    COUNT(*) AS web_txn_count
  FROM web_sales ws
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  WHERE ws.ws_sold_date_sk BETWEEN 2450800 AND 2451100
    AND c.c_preferred_cust_flag = 'Y'
  GROUP BY t.t_hour, c.c_preferred_cust_flag
)
SELECT
  COALESCE(s.hour_of_day, w.hour_of_day) AS hour_of_day,
  COALESCE(s.pref_flag, w.pref_flag) AS pref_flag,
  s.store_net_profit,
  w.web_net_profit,
  (s.store_net_profit + w.web_net_profit) AS total_net_profit,
  (s.store_txn_count + w.web_txn_count) AS total_txn_count,
  CASE
    WHEN (s.store_net_paid_inc_tax + w.web_net_paid_inc_tax) = 0 THEN 0
    ELSE (s.store_net_profit + w.web_net_profit) / (s.store_net_paid_inc_tax + w.web_net_paid_inc_tax)
  END AS profit_margin
FROM store_agg s
FULL OUTER JOIN web_agg w
  ON s.hour_of_day = w.hour_of_day
  AND s.pref_flag = w.pref_flag
ORDER BY hour_of_day
