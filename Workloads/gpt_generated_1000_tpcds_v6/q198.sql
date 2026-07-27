SELECT
    r.r_reason_desc,
    cd_refunded.cd_gender AS refunded_gender,
    cd_returning.cd_gender AS returning_gender,
    wp_ret.wp_type AS page_type,
    SUM(wr.wr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt,
    AVG(wr.wr_return_quantity) AS avg_return_qty
FROM web_returns wr
JOIN customer cust_refunded
  ON wr.wr_refunded_customer_sk = cust_refunded.c_customer_sk
JOIN customer_demographics cd_refunded
  ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN customer cust_returning
  ON wr.wr_returning_customer_sk = cust_returning.c_customer_sk
JOIN customer_demographics cd_returning
  ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN web_page wp_ret
  ON wr.wr_web_page_sk = wp_ret.wp_web_page_sk
JOIN reason r
  ON wr.wr_reason_sk = r.r_reason_sk
JOIN customer cust_page
  ON wp_ret.wp_customer_sk = cust_page.c_customer_sk
JOIN customer_demographics cd_page_current
  ON cust_page.c_current_cdemo_sk = cd_page_current.cd_demo_sk
JOIN customer_demographics cd_refunded_current
  ON cust_refunded.c_current_cdemo_sk = cd_refunded_current.cd_demo_sk
WHERE cust_refunded.c_preferred_cust_flag = 'Y'
  AND cd_refunded.cd_dep_college_count >= 1
  AND wp_ret.wp_link_count > 5
GROUP BY
    r.r_reason_desc,
    cd_refunded.cd_gender,
    cd_returning.cd_gender,
    wp_ret.wp_type
ORDER BY total_net_loss DESC
LIMIT 100
