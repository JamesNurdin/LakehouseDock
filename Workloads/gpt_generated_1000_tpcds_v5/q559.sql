WITH filtered_catalog AS (
    SELECT
        cr.cr_returned_time_sk,
        cr.cr_returned_date_sk,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        cr.cr_order_number,
        cp.cp_department,
        cp.cp_catalog_page_number,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        t.t_hour
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE cp.cp_department = 'Electronics'
      AND cp.cp_catalog_page_number IN (7, 18)
      AND cd.cd_purchase_estimate BETWEEN 5000 AND 10000
      AND cd.cd_dep_count = 2
      AND t.t_hour BETWEEN 9 AND 17
)
SELECT
    fc.cp_department,
    fc.t_hour,
    fc.cd_gender,
    COUNT(DISTINCT fc.cr_order_number) AS distinct_catalog_orders,
    SUM(fc.cr_net_loss) AS catalog_net_loss,
    SUM(sr.sr_net_loss) AS store_net_loss,
    SUM(wr.wr_net_loss) AS web_net_loss,
    (SUM(fc.cr_net_loss) + SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss)) AS total_net_loss,
    CASE
        WHEN (SUM(fc.cr_net_loss) + SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss)) > 10000 THEN 'HIGH'
        ELSE 'LOW'
    END AS loss_category,
    (
        SELECT AVG(wr2.wr_refunded_cash)
        FROM web_returns wr2
        WHERE wr2.wr_returned_time_sk = fc.cr_returned_time_sk
          AND wr2.wr_refunded_cash IS NOT NULL
    ) AS avg_web_refunded_cash_same_time
FROM filtered_catalog fc
JOIN store_returns sr
    ON sr.sr_return_time_sk = fc.cr_returned_time_sk
JOIN time_dim t2
    ON sr.sr_return_time_sk = t2.t_time_sk
JOIN customer_demographics cd_store
    ON sr.sr_cdemo_sk = cd_store.cd_demo_sk
JOIN web_returns wr
    ON wr.wr_returned_time_sk = fc.cr_returned_time_sk
JOIN customer_demographics cd_web
    ON wr.wr_refunded_cdemo_sk = cd_web.cd_demo_sk
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr_exist
    WHERE wr_exist.wr_returned_time_sk = fc.cr_returned_time_sk
      AND wr_exist.wr_return_quantity > 1
      AND wr_exist.wr_refunded_cash > 200
)
GROUP BY
    fc.cp_department,
    fc.t_hour,
    fc.cd_gender,
    fc.cr_returned_time_sk
HAVING (SUM(fc.cr_net_loss) + SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss)) > 5000
ORDER BY total_net_loss DESC
LIMIT 100
