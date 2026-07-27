WITH combined AS (
    SELECT
        s.s_store_id AS store_id,
        s.s_state AS state,
        r.r_reason_desc AS reason_desc,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(*) AS total_returns,
        CASE
            WHEN (SUM(sr.sr_net_loss) + SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) > 0 THEN 'Loss'
            ELSE 'NoLoss'
        END AS loss_flag
    FROM store_returns sr
    JOIN time_dim td
        ON sr.sr_return_time_sk = td.t_time_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_time_sk = td.t_time_sk
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
        AND cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_returns wr
        ON wr.wr_returned_time_sk = td.t_time_sk
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE td.t_hour BETWEEN 8 AND 17
      AND s.s_state = 'CA'
      AND ca.ca_county IN ('Mifflin County', 'York County')
      AND r.r_reason_desc LIKE '%damaged%'
      AND sr.sr_refunded_cash > 100
      AND cr.cr_return_amount > 50
      AND wr.wr_return_quantity > 1
      AND cd.cd_dep_count <= 2
    GROUP BY s.s_store_id, s.s_state, r.r_reason_desc
)
SELECT
    store_id,
    state,
    AVG(store_net_loss + catalog_net_loss + web_net_loss) AS avg_total_net_loss,
    SUM(total_returns) AS total_return_events,
    COUNT(DISTINCT reason_desc) AS distinct_reasons,
    MAX(CASE WHEN loss_flag = 'Loss' THEN 1 ELSE 0 END) AS any_loss_flag
FROM combined
GROUP BY store_id, state
HAVING AVG(store_net_loss + catalog_net_loss + web_net_loss) > 200
ORDER BY avg_total_net_loss DESC
LIMIT 100
