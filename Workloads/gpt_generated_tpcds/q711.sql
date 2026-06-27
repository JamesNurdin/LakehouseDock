WITH combined AS (
    SELECT 'Catalog' AS return_channel,
           r.r_reason_desc AS reason_desc,
           c.c_preferred_cust_flag AS preferred_cust_flag,
           cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk

    UNION ALL

    SELECT 'Store' AS return_channel,
           r.r_reason_desc,
           c.c_preferred_cust_flag,
           sr.sr_net_loss
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk

    UNION ALL

    SELECT 'Web' AS return_channel,
           r.r_reason_desc,
           c.c_preferred_cust_flag,
           wr.wr_net_loss
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
),
agg AS (
    SELECT return_channel,
           reason_desc,
           preferred_cust_flag,
           COUNT(*) AS return_cnt,
           SUM(net_loss) AS total_net_loss,
           AVG(net_loss) AS avg_net_loss
    FROM combined
    GROUP BY return_channel, reason_desc, preferred_cust_flag
)
SELECT return_channel,
       reason_desc,
       preferred_cust_flag,
       return_cnt,
       total_net_loss,
       avg_net_loss,
       RANK() OVER (PARTITION BY return_channel ORDER BY total_net_loss DESC) AS loss_rank
FROM agg
ORDER BY return_channel, loss_rank
