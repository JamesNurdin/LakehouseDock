WITH
store_ret_agg AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_addr_sk,
        sr.sr_reason_sk,
        SUM(sr.sr_net_loss) AS store_net_loss,
        COUNT(*) AS store_ret_cnt
    FROM store_returns sr
    GROUP BY sr.sr_store_sk, sr.sr_addr_sk, sr.sr_reason_sk
),
catalog_ret_agg AS (
    SELECT
        cr.cr_warehouse_sk,
        cr.cr_ship_mode_sk,
        cr.cr_refunded_addr_sk,
        cr.cr_reason_sk,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        COUNT(*) AS catalog_ret_cnt
    FROM catalog_returns cr
    GROUP BY cr.cr_warehouse_sk, cr.cr_ship_mode_sk, cr.cr_refunded_addr_sk, cr.cr_reason_sk
),
web_ret_agg AS (
    SELECT
        wr.wr_refunded_addr_sk,
        wr.wr_reason_sk,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(*) AS web_ret_cnt
    FROM web_returns wr
    GROUP BY wr.wr_refunded_addr_sk, wr.wr_reason_sk
),
joined_data AS (
    SELECT
        s.s_store_id,
        w.w_warehouse_id,
        sm.sm_type AS ship_mode_type,
        ca_refunded.ca_state                     AS refunded_state,
        ca_web_refunded.ca_state                 AS returning_state,
        r_sr.r_reason_desc                       AS store_reason,
        r_cr.r_reason_desc                       AS catalog_reason,
        r_wr.r_reason_desc                       AS web_reason,
        sr.store_net_loss,
        cr.catalog_net_loss,
        wr.web_net_loss,
        CASE
            WHEN sr.store_net_loss > cr.catalog_net_loss THEN 'StoreHigher'
            WHEN cr.catalog_net_loss > wr.web_net_loss THEN 'CatalogHigher'
            ELSE 'WebHigherOrEqual'
        END                                      AS loss_comparison,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY sr.store_net_loss DESC) AS rn_store_loss,
        orders_l.orders_per_store
    FROM store s
    FULL OUTER JOIN store_ret_agg sr
        ON s.s_store_sk = sr.sr_store_sk
    LEFT JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN customer_address ca_refunded
        ON sr.sr_addr_sk = ca_refunded.ca_address_sk
    LEFT JOIN catalog_ret_agg cr
        ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    LEFT JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN reason r_cr
        ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN web_ret_agg wr
        ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
    LEFT JOIN customer_address ca_web_refunded
        ON wr.wr_refunded_addr_sk = ca_web_refunded.ca_address_sk
    LEFT JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN LATERAL (
        SELECT COUNT(*) AS orders_per_store
        FROM store_returns sr2
        WHERE sr2.sr_store_sk = s.s_store_sk
    ) orders_l ON true
    WHERE NOT EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_returning_addr_sk = ca_refunded.ca_address_sk
    )
)
SELECT DISTINCT
    s_store_id,
    w_warehouse_id,
    ship_mode_type,
    refunded_state,
    returning_state,
    store_reason,
    catalog_reason,
    web_reason,
    store_net_loss,
    catalog_net_loss,
    web_net_loss,
    loss_comparison,
    orders_per_store
FROM joined_data
WHERE loss_comparison = 'StoreHigher' AND rn_store_loss = 1

UNION

SELECT DISTINCT
    s_store_id,
    w_warehouse_id,
    ship_mode_type,
    refunded_state,
    returning_state,
    store_reason,
    catalog_reason,
    web_reason,
    store_net_loss,
    catalog_net_loss,
    web_net_loss,
    loss_comparison,
    orders_per_store
FROM joined_data
WHERE loss_comparison = 'CatalogHigher' AND rn_store_loss = 2

ORDER BY store_net_loss DESC
LIMIT 100
