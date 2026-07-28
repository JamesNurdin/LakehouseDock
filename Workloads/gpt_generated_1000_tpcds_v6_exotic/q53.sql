WITH joined_data AS (
    SELECT
        s.s_store_name,
        cp.cp_catalog_number,
        r.r_reason_desc,
        SUM(cr.cr_net_loss + sr.sr_net_loss) AS total_net_loss,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_returns_cnt,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_returns_cnt,
        AVG(cr.cr_return_quantity) AS avg_catalog_return_qty,
        AVG(sr.sr_return_quantity) AS avg_store_return_qty
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim t_cr
        ON cr.cr_returned_time_sk = t_cr.t_time_sk
    JOIN customer_demographics cd_refund
        ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
    JOIN customer_address ca_refund
        ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN store_returns sr
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim t_sr
        ON sr.sr_return_time_sk = t_sr.t_time_sk
    JOIN customer_demographics cd_store
        ON sr.sr_cdemo_sk = cd_store.cd_demo_sk
    JOIN customer_address ca_store
        ON sr.sr_addr_sk = ca_store.ca_address_sk
    WHERE
        t_cr.t_shift = 'first'
        AND t_sr.t_hour = 10
        AND cp.cp_catalog_number IN (3, 15)
        AND ca_refund.ca_gmt_offset = -6.00
        AND s.s_state = 'CA'
        AND s.s_store_sk IN (
            SELECT sr2.sr_store_sk
            FROM store_returns sr2
            GROUP BY sr2.sr_store_sk
            HAVING COUNT(*) > 20
        )
    GROUP BY
        s.s_store_name,
        cp.cp_catalog_number,
        r.r_reason_desc
    HAVING
        SUM(cr.cr_net_loss + sr.sr_net_loss) > 1000
)
SELECT
    jd.s_store_name,
    jd.cp_catalog_number,
    jd.r_reason_desc,
    jd.total_net_loss,
    jd.catalog_returns_cnt,
    jd.store_returns_cnt,
    jd.avg_catalog_return_qty,
    jd.avg_store_return_qty,
    RANK() OVER (ORDER BY jd.total_net_loss DESC) AS loss_rank,
    (SELECT AVG(cr_net_loss) FROM catalog_returns) AS overall_avg_cat_net_loss
FROM joined_data jd
ORDER BY jd.total_net_loss DESC
LIMIT 100
