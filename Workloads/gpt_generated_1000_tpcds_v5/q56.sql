WITH
    cr AS (
        SELECT
            cr_returned_date_sk,
            cr_returned_time_sk,
            cr_call_center_sk,
            cr_catalog_page_sk,
            cr_warehouse_sk,
            cr_return_quantity,
            cr_return_amount,
            cr_net_loss,
            cr_returning_hdemo_sk,
            cr_refunded_hdemo_sk
        FROM catalog_returns
        WHERE cr_return_amount > 100
          AND cr_return_quantity >= 1
    ),
    d_ret AS (
        SELECT *
        FROM date_dim
        WHERE d_year = 2001
    ),
    t AS (
        SELECT *
        FROM time_dim
        WHERE t_hour BETWEEN 8 AND 17
    ),
    cc AS (
        SELECT *
        FROM call_center
        WHERE cc_state = 'CA'
    ),
    cp AS (
        SELECT *
        FROM catalog_page
        WHERE cp_type = 'A'
    ),
    w AS (
        SELECT *
        FROM warehouse
        WHERE w_country = 'United States'
    ),
    hd_ret AS (
        SELECT *
        FROM household_demographics
        WHERE hd_income_band_sk BETWEEN 5 AND 10
    ),
    s AS (
        SELECT *
        FROM store
        WHERE s_state = 'CA'
    ),
    wp AS (
        SELECT *
        FROM web_page
        WHERE wp_link_count > 10
    )
SELECT
    cc.cc_call_center_id,
    cp.cp_catalog_page_id,
    w.w_warehouse_name,
    d_ret.d_date,
    t.t_hour,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_call_center_id ORDER BY SUM(cr.cr_net_loss) DESC) AS net_loss_rank,
    CASE
        WHEN SUM(cr.cr_net_loss) > 10000 THEN 'HIGH'
        WHEN SUM(cr.cr_net_loss) > 5000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS loss_category
FROM cr
JOIN d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN t ON cr.cr_returned_time_sk = t.t_time_sk
JOIN cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN s ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN wp ON wp.wp_creation_date_sk = d_ret.d_date_sk
GROUP BY
    cc.cc_call_center_id,
    cp.cp_catalog_page_id,
    w.w_warehouse_name,
    d_ret.d_date,
    t.t_hour
ORDER BY
    total_net_loss DESC,
    net_loss_rank ASC
LIMIT 100
