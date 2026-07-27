SELECT reason_desc,
       page_type,
       total_net_loss,
       return_cnt,
       loss_category
FROM (
    SELECT r.r_reason_desc AS reason_desc,
           wp.wp_type AS page_type,
           SUM(wr.wr_net_loss) AS total_net_loss,
           COUNT(*) AS return_cnt,
           CASE WHEN SUM(wr.wr_net_loss) > 10000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE r.r_reason_desc = 'Did not get it on time'
      AND wp.wp_rec_start_date BETWEEN DATE '1999-01-01' AND DATE '2000-12-31'
    GROUP BY r.r_reason_desc, wp.wp_type
    HAVING SUM(wr.wr_net_loss) > 5000

    UNION ALL

    SELECT r.r_reason_desc AS reason_desc,
           wp.wp_type AS page_type,
           SUM(wr.wr_net_loss) AS total_net_loss,
           COUNT(*) AS return_cnt,
           CASE WHEN SUM(wr.wr_net_loss) > 10000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE r.r_reason_desc = 'No service location in my area'
      AND wp.wp_char_count > 2000
    GROUP BY r.r_reason_desc, wp.wp_type
    HAVING SUM(wr.wr_net_loss) > 5000
) AS combined
ORDER BY total_net_loss DESC
LIMIT 100
