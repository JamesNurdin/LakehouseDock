WITH union_data AS (
    SELECT
        'Reason' AS category_type,
        r.r_reason_desc AS category_name,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_amount) AS avg_return_amount
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND EXISTS (
          SELECT 1
          FROM customer_demographics cd
          WHERE cd.cd_demo_sk = cr.cr_refunded_cdemo_sk
            AND cd.cd_gender = 'F'
      )
    GROUP BY r.r_reason_desc
    HAVING SUM(cr.cr_net_loss) > 1000

    UNION ALL

    SELECT
        'WebPage' AS category_type,
        wp.wp_type AS category_name,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_amount) AS avg_return_amount
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND wp.wp_type IS NOT NULL
    GROUP BY wp.wp_type
    HAVING SUM(cr.cr_net_loss) > 1000
)
SELECT DISTINCT
    category_type,
    category_name,
    total_net_loss,
    avg_return_amount,
    (SELECT MAX(d_year) FROM date_dim) AS max_year,
    ROW_NUMBER() OVER (PARTITION BY category_type ORDER BY total_net_loss DESC) AS loss_rank
FROM union_data
ORDER BY total_net_loss DESC
LIMIT 100
