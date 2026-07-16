WITH
    cat AS (
        SELECT
            d.d_date_sk,
            d.d_year,
            d.d_moy,
            cd_ret.cd_gender        AS returning_gender,
            cd_ret.cd_marital_status AS returning_marital_status,
            cd_ref.cd_gender        AS refunded_gender,
            cd_ref.cd_marital_status AS refunded_marital_status,
            SUM(cr.cr_return_amount)   AS total_return_amount,
            SUM(cr.cr_fee)             AS total_fee,
            SUM(cr.cr_return_quantity) AS total_quantity,
            SUM(cr.cr_net_loss)        AS total_net_loss
        FROM catalog_returns cr
        JOIN date_dim d
            ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN customer_demographics cd_ret
            ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
        JOIN customer_demographics cd_ref
            ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
        GROUP BY
            d.d_date_sk,
            d.d_year,
            d.d_moy,
            cd_ret.cd_gender,
            cd_ret.cd_marital_status,
            cd_ref.cd_gender,
            cd_ref.cd_marital_status
    ),
    web AS (
        SELECT
            d.d_date_sk,
            d.d_year,
            d.d_moy,
            cd_ret.cd_gender        AS returning_gender,
            cd_ret.cd_marital_status AS returning_marital_status,
            cd_ref.cd_gender        AS refunded_gender,
            cd_ref.cd_marital_status AS refunded_marital_status,
            SUM(wr.wr_return_amt)     AS total_return_amount,
            SUM(wr.wr_fee)            AS total_fee,
            SUM(wr.wr_return_quantity) AS total_quantity,
            SUM(wr.wr_net_loss)       AS total_net_loss
        FROM web_returns wr
        JOIN date_dim d
            ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN customer_demographics cd_ret
            ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
        JOIN customer_demographics cd_ref
            ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
        GROUP BY
            d.d_date_sk,
            d.d_year,
            d.d_moy,
            cd_ret.cd_gender,
            cd_ret.cd_marital_status,
            cd_ref.cd_gender,
            cd_ref.cd_marital_status
    ),
    store_info AS (
        SELECT
            d.d_date_sk,
            s.s_state,
            COUNT(*) AS stores_closed
        FROM store s
        JOIN date_dim d
            ON s.s_closed_date_sk = d.d_date_sk
        GROUP BY
            d.d_date_sk,
            s.s_state
    )
SELECT
    d.d_year,
    d.d_moy AS month,
    COALESCE(cat.returning_gender, web.returning_gender)           AS returning_gender,
    COALESCE(cat.returning_marital_status, web.returning_marital_status) AS returning_marital_status,
    COALESCE(cat.refunded_gender, web.refunded_gender)           AS refunded_gender,
    COALESCE(cat.refunded_marital_status, web.refunded_marital_status) AS refunded_marital_status,
    si.s_state,
    COALESCE(si.stores_closed, 0)                                 AS stores_closed,
    COALESCE(cat.total_return_amount, 0) + COALESCE(web.total_return_amount, 0) AS total_return_amount,
    COALESCE(cat.total_fee, 0) + COALESCE(web.total_fee, 0)                     AS total_fee,
    COALESCE(cat.total_quantity, 0) + COALESCE(web.total_quantity, 0)           AS total_quantity,
    COALESCE(cat.total_net_loss, 0) + COALESCE(web.total_net_loss, 0)           AS total_net_loss,
    ROW_NUMBER() OVER (
        PARTITION BY d.d_year
        ORDER BY COALESCE(cat.total_net_loss, 0) + COALESCE(web.total_net_loss, 0) DESC
    ) AS rank_by_year_net_loss
FROM date_dim d
LEFT JOIN cat        ON cat.d_date_sk = d.d_date_sk
LEFT JOIN web        ON web.d_date_sk = d.d_date_sk
LEFT JOIN store_info si ON si.d_date_sk = d.d_date_sk
WHERE COALESCE(cat.total_net_loss, 0) + COALESCE(web.total_net_loss, 0) > 0
ORDER BY
    d.d_year,
    rank_by_year_net_loss
