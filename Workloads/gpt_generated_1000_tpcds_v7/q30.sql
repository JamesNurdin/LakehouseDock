WITH base AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_item_sk,
        cr.cr_ship_mode_sk,
        cr.cr_warehouse_sk,
        cr.cr_refunded_cdemo_sk,
        cr.cr_returning_cdemo_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_return_quantity,
        cr.cr_order_number
    FROM catalog_returns cr
)
SELECT
    d_ret.d_year,
    w.w_state,
    sm.sm_type,
    cd_ret.cd_gender,
    SUM(base.cr_return_amount)          AS total_return_amount,
    SUM(base.cr_net_loss)               AS total_net_loss,
    COUNT(*)                            AS return_cnt,
    AVG(i.i_current_price)              AS avg_item_price,
    COALESCE(sm2.sm_type, 'UNKNOWN')    AS ship_type_fallback,
    MAX(wp.wp_url) FILTER (WHERE wp.wp_url IS NOT NULL) AS sample_wp_url
FROM base
JOIN date_dim d_ret
    ON base.cr_returned_date_sk = d_ret.d_date_sk                                   -- returned date
JOIN item i
    ON base.cr_item_sk = i.i_item_sk
JOIN ship_mode sm
    ON base.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN ship_mode sm2
    ON base.cr_ship_mode_sk = sm2.sm_ship_mode_sk                                   -- same key, different role (outer join)
JOIN warehouse w
    ON base.cr_warehouse_sk = w.w_warehouse_sk
JOIN customer_demographics cd_ref
    ON base.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_demographics cd_ret
    ON base.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_ret.d_date_sk                                   -- first link to date_dim (creation date)
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk                                 -- second link to date_dim (access date)
WHERE d_ret.d_date >= DATE '2001-01-01'
  AND d_ret.d_date <  DATE '2002-01-01'
  AND wp.wp_url LIKE 'http://www.%'
GROUP BY
    d_ret.d_year,
    w.w_state,
    sm.sm_type,
    cd_ret.cd_gender,
    sm2.sm_type
ORDER BY total_net_loss DESC, d_ret.d_year ASC
LIMIT 100
