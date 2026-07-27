WITH customer_fact AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_current_hdemo_sk,
        SUM(cr.cr_net_loss)               AS total_catalog_net_loss,
        SUM(sr.sr_net_loss)               AS total_store_net_loss,
        SUM(wr.wr_net_loss)               AS total_web_net_loss,
        MAX(cr.cr_reason_sk)              AS catalog_reason_sk,
        MAX(sr.sr_reason_sk)              AS store_reason_sk,
        MAX(wr.wr_reason_sk)              AS web_reason_sk,
        MAX(cr.cr_ship_mode_sk)           AS catalog_ship_mode_sk,
        MAX(sr.sr_store_sk)               AS store_sk
    FROM
        customer c
        LEFT JOIN catalog_returns cr ON cr.cr_refunded_customer_sk = c.c_customer_sk
        LEFT JOIN store_returns   sr ON sr.sr_customer_sk      = c.c_customer_sk
        LEFT JOIN web_returns     wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE
        c.c_birth_year BETWEEN 1950 AND 1960                     -- predicate 1
        AND c.c_preferred_cust_flag = 'Y'                         -- predicate 2
        AND cr.cr_return_quantity > 1                             -- predicate 3
        AND sr.sr_return_quantity > 1                             -- predicate 4
        AND wr.wr_return_quantity > 1                             -- predicate 5
        AND cr.cr_fee > 20.00                                      -- predicate 6
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        c.c_current_hdemo_sk
),
ranked_customers AS (
    SELECT
        cf.c_customer_sk,
        cf.c_customer_id,
        cf.total_catalog_net_loss,
        cf.total_store_net_loss,
        cf.total_web_net_loss,
        (COALESCE(cf.total_catalog_net_loss,0) +
         COALESCE(cf.total_store_net_loss,0) +
         COALESCE(cf.total_web_net_loss,0))               AS total_net_loss,
        RANK() OVER (ORDER BY (COALESCE(cf.total_catalog_net_loss,0) +
                               COALESCE(cf.total_store_net_loss,0) +
                               COALESCE(cf.total_web_net_loss,0)) DESC) AS loss_rank,
        cf.catalog_reason_sk,
        cf.store_reason_sk,
        cf.web_reason_sk,
        cf.catalog_ship_mode_sk,
        cf.store_sk,
        cf.c_current_hdemo_sk
    FROM customer_fact cf
)
SELECT DISTINCT
    rc.c_customer_id,
    rc.total_catalog_net_loss,
    rc.total_store_net_loss,
    rc.total_web_net_loss,
    rc.total_net_loss,
    rc.loss_rank,
    hd.hd_buy_potential,
    hd.hd_dep_count,
    hd.hd_vehicle_count,
    sm.sm_carrier,
    r.r_reason_desc,
    s.s_store_name
FROM ranked_customers rc
-- Join to household demographics via the customer’s current household demo key
JOIN household_demographics hd ON rc.c_current_hdemo_sk = hd.hd_demo_sk
-- Join to ship mode using the catalog return’s ship mode (if present)
LEFT JOIN ship_mode sm ON rc.catalog_ship_mode_sk = sm.sm_ship_mode_sk
-- Choose a reason: prefer catalog reason, otherwise store, otherwise web
LEFT JOIN reason r ON (
        rc.catalog_reason_sk = r.r_reason_sk OR
        rc.store_reason_sk   = r.r_reason_sk OR
        rc.web_reason_sk     = r.r_reason_sk
    )
-- Join to store via the store key captured from store_returns (if any)
LEFT JOIN store s ON rc.store_sk = s.s_store_sk
WHERE
    rc.loss_rank <= 10                     -- keep only top‑10 loss makers
ORDER BY rc.loss_rank, rc.c_customer_id
