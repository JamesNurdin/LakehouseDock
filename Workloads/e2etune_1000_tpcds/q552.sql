SELECT
    cc.cc_state,
    d.d_year,
    d.d_quarter_seq,
    SUM(ss.ss_net_profit) AS total_store_profit,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
    COUNT(DISTINCT ss.ss_customer_sk) AS distinct_store_customers,
    COUNT(DISTINCT wr.wr_refunded_customer_sk) AS distinct_return_customers,
    SUM(CASE WHEN cd.cd_gender = 'M' THEN ss.ss_net_profit ELSE 0 END) AS male_profit,
    SUM(CASE WHEN cd.cd_gender = 'F' THEN ss.ss_net_profit ELSE 0 END) AS female_profit
FROM call_center cc
JOIN date_dim d
  ON d.d_date_sk BETWEEN cc.cc_open_date_sk AND cc.cc_closed_date_sk
JOIN store_sales ss
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN web_returns wr
  ON wr.wr_returned_date_sk = d.d_date_sk
  AND wr.wr_refunded_customer_sk = c.c_customer_sk
  AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
LEFT JOIN reason r
  ON wr.wr_reason_sk = r.r_reason_sk
WHERE d.d_year = 2001
  AND cc.cc_state IN ('TN', 'GA')
  AND cd.cd_marital_status = 'M'
  AND (r.r_reason_desc LIKE '%defective%' OR r.r_reason_desc IS NULL)
GROUP BY cc.cc_state, d.d_year, d.d_quarter_seq
HAVING SUM(ss.ss_net_profit) > 10000
ORDER BY total_store_profit DESC
LIMIT 50
