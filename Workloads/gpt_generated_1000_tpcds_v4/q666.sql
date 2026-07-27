SELECT
    s.s_store_name,
    cc.cc_name,
    w.web_name,
    r.r_reason_desc,
    cd_ref.cd_gender,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(wr.wr_net_loss) AS avg_net_loss,
    COUNT(*) AS return_count
FROM web_returns wr
JOIN date_dim d
  ON wr.wr_returned_date_sk = d.d_date_sk
JOIN reason r
  ON wr.wr_reason_sk = r.r_reason_sk
JOIN customer c_ref
  ON wr.wr_refunded_customer_sk = c_ref.c_customer_sk
JOIN customer_demographics cd_ref
  ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer c_ret
  ON wr.wr_returning_customer_sk = c_ret.c_customer_sk
JOIN customer_demographics cd_ret
  ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN store s
  ON s.s_closed_date_sk = d.d_date_sk
JOIN call_center cc
  ON cc.cc_closed_date_sk = d.d_date_sk
JOIN web_site w
  ON w.web_open_date_sk = d.d_date_sk
GROUP BY
    s.s_store_name,
    cc.cc_name,
    w.web_name,
    r.r_reason_desc,
    cd_ref.cd_gender
ORDER BY total_return_amount DESC
LIMIT 100
