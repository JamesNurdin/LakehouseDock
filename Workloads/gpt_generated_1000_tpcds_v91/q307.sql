WITH cat_agg AS (
    SELECT
        cr.cr_refunded_customer_sk AS customer_sk,
        c.c_last_name,
        cd.cd_gender,
        SUM(cr.cr_return_quantity) AS total_qty,
        SUM(cr.cr_return_amount) AS total_amt,
        SUM(cr.cr_net_loss) AS total_net_loss,
        CASE WHEN SUM(cr.cr_net_loss) > 500 THEN 'High' ELSE 'Low' END AS loss_category
    FROM catalog_returns cr
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cr.cr_return_amount > 20
    GROUP BY cr.cr_refunded_customer_sk, c.c_last_name, cd.cd_gender
),
web_agg AS (
    SELECT
        wr.wr_refunded_customer_sk AS customer_sk,
        c.c_last_name,
        cd.cd_gender,
        SUM(wr.wr_return_quantity) AS total_qty,
        SUM(wr.wr_return_amt) AS total_amt,
        SUM(wr.wr_net_loss) AS total_net_loss,
        CASE WHEN SUM(wr.wr_net_loss) > 400 THEN 'High' ELSE 'Low' END AS loss_category
    FROM web_returns wr
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE wp.wp_rec_start_date >= DATE '2000-09-03'
      AND wp.wp_image_count >= 4
    GROUP BY wr.wr_refunded_customer_sk, c.c_last_name, cd.cd_gender
),
common_customers AS (
    SELECT customer_sk FROM cat_agg
    INTERSECT
    SELECT customer_sk FROM web_agg
)
SELECT
    ca.customer_sk,
    ca.c_last_name,
    ca.cd_gender,
    ca.total_qty AS cat_total_qty,
    ca.total_amt AS cat_total_amt,
    ca.loss_category AS cat_loss_category,
    wa.total_qty AS web_total_qty,
    wa.total_amt AS web_total_amt,
    wa.loss_category AS web_loss_category,
    (
        SELECT AVG(cr.cr_return_amount)
        FROM catalog_returns cr
        WHERE cr.cr_refunded_customer_sk = ca.customer_sk
    ) AS avg_catalog_return_amount,
    EXISTS (
        SELECT 1
        FROM web_page wp2
        WHERE wp2.wp_customer_sk = ca.customer_sk
          AND wp2.wp_max_ad_count > 5
    ) AS has_high_ad_page
FROM common_customers cc
LEFT JOIN cat_agg ca ON cc.customer_sk = ca.customer_sk
LEFT JOIN web_agg wa ON cc.customer_sk = wa.customer_sk
WHERE ca.loss_category = 'High' OR wa.loss_category = 'High'
ORDER BY ca.total_amt DESC, wa.total_amt DESC
LIMIT 100
