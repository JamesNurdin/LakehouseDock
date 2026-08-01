WITH distinct_return_customers AS (
        SELECT cr.cr_refunded_customer_sk AS customer_sk
        FROM catalog_returns cr
        WHERE cr.cr_return_amount > 200
        UNION
        SELECT sr.sr_customer_sk AS customer_sk
        FROM store_returns sr
        WHERE sr.sr_return_amt > 150
    )
SELECT
    c.c_customer_id,
    cd.cd_gender,
    sm.sm_type,
    td.t_hour,
    COUNT(DISTINCT cr.cr_order_number)               AS catalog_orders,
    SUM(cr.cr_return_amount)                         AS total_catalog_return,
    SUM(sr.sr_return_amt)                            AS total_store_return,
    SUM(wr.wr_return_amt)                            AS total_web_return,
    AVG(cr.cr_net_loss)                              AS avg_catalog_net_loss,
    MIN(sr.sr_net_loss)                              AS min_store_net_loss,
    MAX(wr.wr_net_loss)                              AS max_web_net_loss
FROM store_returns sr
JOIN time_dim td
    ON sr.sr_return_time_sk = td.t_time_sk
JOIN customer c
    ON sr.sr_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN catalog_returns cr
    ON cr.cr_returned_time_sk = td.t_time_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN web_returns wr
    ON wr.wr_returned_time_sk = td.t_time_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE
    td.t_am_pm = 'PM'
    AND td.t_second = 12
    AND w.w_street_type = 'Avenue'
    AND sm.sm_type = 'AIR'
    AND c.c_birth_year = 1990
    AND wp.wp_customer_sk = c.c_customer_sk
    AND c.c_customer_sk IN (SELECT customer_sk FROM distinct_return_customers)
GROUP BY
    c.c_customer_id,
    cd.cd_gender,
    sm.sm_type,
    td.t_hour
HAVING COUNT(DISTINCT cr.cr_order_number) > 5
ORDER BY total_catalog_return DESC
LIMIT 100
