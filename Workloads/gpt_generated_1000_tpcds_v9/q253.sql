WITH raw AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_birth_month,
        cd.cd_gender,
        cd.cd_marital_status,
        sr.sr_net_loss,
        cr.cr_net_loss,
        wr.wr_net_loss,
        cr.cr_reason_sk,
        sr.sr_reason_sk,
        wr.wr_reason_sk,
        sm.sm_type,
        cp.cp_department,
        wr.wr_return_quantity,
        t_store.t_hour AS store_hour,
        t_catalog.t_hour AS catalog_hour,
        t_web.t_hour AS web_hour
    FROM
        customer c
        JOIN customer_demographics cd
            ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN store_returns sr
            ON sr.sr_customer_sk = c.c_customer_sk
        JOIN time_dim t_store
            ON sr.sr_return_time_sk = t_store.t_time_sk
        JOIN catalog_returns cr
            ON cr.cr_refunded_customer_sk = c.c_customer_sk
        JOIN time_dim t_catalog
            ON cr.cr_returned_time_sk = t_catalog.t_time_sk
        JOIN catalog_page cp
            ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm
            ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN web_returns wr
            ON wr.wr_refunded_customer_sk = c.c_customer_sk
        JOIN time_dim t_web
            ON wr.wr_returned_time_sk = t_web.t_time_sk
        LEFT JOIN web_page wp
            ON wr.wr_web_page_sk = wp.wp_web_page_sk
            AND wp.wp_image_count >= 5
    WHERE
        c.c_birth_month IN (6, 7, 8)                     -- predicate 1
        AND t_store.t_hour BETWEEN 9 AND 17               -- predicate 2
        AND sm.sm_type = 'AIR'                            -- predicate 3
        AND cp.cp_department = 'Electronics'              -- predicate 4
        AND wr.wr_return_quantity > 1                    -- predicate 5
),
aggregated AS (
    SELECT
        c_customer_sk,
        c_customer_id,
        c_birth_month,
        cd_gender,
        cd_marital_status,
        SUM(sr_net_loss) AS total_store_net_loss,
        SUM(cr_net_loss) AS total_catalog_net_loss,
        SUM(wr_net_loss) AS total_web_net_loss,
        SUM(sr_net_loss + cr_net_loss + wr_net_loss) AS total_net_loss,
        COUNT(DISTINCT cr_reason_sk) AS distinct_catalog_return_reasons,
        COUNT(DISTINCT sr_reason_sk) AS distinct_store_return_reasons,
        COUNT(DISTINCT wr_reason_sk) AS distinct_web_return_reasons,
        CASE
            WHEN SUM(sr_net_loss + cr_net_loss + wr_net_loss) > 1000 THEN 'High Loss'
            ELSE 'Low Loss'
        END AS loss_category
    FROM raw
    GROUP BY
        c_customer_sk,
        c_customer_id,
        c_birth_month,
        cd_gender,
        cd_marital_status
)
SELECT
    a.c_customer_sk,
    a.c_customer_id,
    a.c_birth_month,
    a.cd_gender,
    a.cd_marital_status,
    a.total_store_net_loss,
    a.total_catalog_net_loss,
    a.total_web_net_loss,
    a.total_net_loss,
    a.distinct_catalog_return_reasons,
    a.distinct_store_return_reasons,
    a.distinct_web_return_reasons,
    a.loss_category,
    RANK() OVER (ORDER BY a.total_net_loss DESC) AS loss_rank,
    (SELECT MAX(sr2.sr_returned_date_sk)
       FROM store_returns sr2
      WHERE sr2.sr_customer_sk = a.c_customer_sk) AS latest_store_return_date
FROM aggregated a
WHERE a.total_net_loss > 0
ORDER BY a.total_net_loss DESC
LIMIT 10
