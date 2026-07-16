WITH agg_returns AS (
    SELECT
        r.r_reason_desc,
        cd.cd_gender,
        cd.cd_marital_status,
        wp.wp_type,
        COUNT(*) AS return_count,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_amt) AS avg_return_amount
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
        AND wp.wp_customer_sk = c.c_customer_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2451545 AND 2451910
      AND wp.wp_type IN ('article', 'product')
    GROUP BY r.r_reason_desc, cd.cd_gender, cd.cd_marital_status, wp.wp_type
    HAVING SUM(wr.wr_net_loss) > 0
)
SELECT
    r_reason_desc,
    cd_gender,
    cd_marital_status,
    wp_type,
    return_count,
    total_net_loss,
    avg_return_amount,
    RANK() OVER (PARTITION BY cd_gender ORDER BY total_net_loss DESC) AS gender_rank
FROM agg_returns
ORDER BY total_net_loss DESC
LIMIT 10
