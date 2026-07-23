WITH catalog_return_summary AS (
    SELECT
        cp.cp_department AS channel,
        cd.cd_gender AS gender,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cp.cp_department IS NOT NULL
      AND cd.cd_gender IS NOT NULL
      AND td.t_hour BETWEEN 9 AND 17
    GROUP BY cp.cp_department, cd.cd_gender
),
web_return_summary AS (
    SELECT
        wp.wp_type AS channel,
        cd.cd_gender AS gender,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count
    FROM web_returns wr
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN time_dim td
        ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE wp.wp_type IS NOT NULL
      AND cd.cd_gender IS NOT NULL
      AND td.t_hour BETWEEN 9 AND 17
    GROUP BY wp.wp_type, cd.cd_gender
)
SELECT *
FROM catalog_return_summary
UNION ALL
SELECT *
FROM web_return_summary
ORDER BY channel, gender, total_return_amount DESC
LIMIT 100
