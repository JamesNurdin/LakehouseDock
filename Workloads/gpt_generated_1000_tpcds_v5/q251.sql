WITH cr_agg AS (
    SELECT
        cr.cr_refunded_customer_sk AS customer_sk,
        SUM(cr.cr_return_amount) AS catalog_return_amount,
        SUM(cr.cr_net_loss) AS catalog_net_loss
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_fee > 20
      AND i.i_current_price < 100
    GROUP BY cr.cr_refunded_customer_sk
),
wr_agg AS (
    SELECT
        wr.wr_refunded_customer_sk AS customer_sk,
        SUM(wr.wr_return_amt) AS web_return_amount,
        SUM(wr.wr_net_loss) AS web_net_loss
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wr.wr_fee > 30
      AND wr.wr_return_quantity >= 10
    GROUP BY wr.wr_refunded_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_education_status,
    COALESCE(cr_agg.catalog_return_amount, 0) + COALESCE(wr_agg.web_return_amount, 0) AS total_return_amount,
    COALESCE(cr_agg.catalog_net_loss, 0) + COALESCE(wr_agg.web_net_loss, 0) AS total_net_loss,
    ROW_NUMBER() OVER (ORDER BY (COALESCE(cr_agg.catalog_net_loss, 0) + COALESCE(wr_agg.web_net_loss, 0)) DESC) AS loss_rank,
    CASE
        WHEN (COALESCE(cr_agg.catalog_net_loss, 0) + COALESCE(wr_agg.web_net_loss, 0)) > 5000 THEN 'HIGH'
        WHEN (COALESCE(cr_agg.catalog_net_loss, 0) + COALESCE(wr_agg.web_net_loss, 0)) > 1000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS loss_category
FROM customer c
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN cr_agg ON cr_agg.customer_sk = c.c_customer_sk
LEFT JOIN wr_agg ON wr_agg.customer_sk = c.c_customer_sk
WHERE cd.cd_purchase_estimate BETWEEN 5000 AND 8000
  AND cd.cd_education_status = 'Advanced Degree'
ORDER BY total_net_loss DESC
LIMIT 100
