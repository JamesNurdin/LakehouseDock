WITH catalog_agg AS (
    SELECT
        ca.ca_state AS state,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        COUNT(*) AS catalog_return_cnt
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE cp.cp_type = 'monthly'
      AND cp.cp_end_date_sk BETWEEN 2450905 AND 2451087
      AND td.t_hour BETWEEN 9 AND 17
    GROUP BY ca.ca_state
),
web_agg AS (
    SELECT
        ca.ca_state AS state,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450905 AND 2451087
      AND td.t_hour BETWEEN 9 AND 17
    GROUP BY ca.ca_state
)
SELECT
    COALESCE(ca.state, wa.state) AS state,
    COALESCE(catalog_net_loss, 0) AS catalog_net_loss,
    COALESCE(web_net_loss, 0) AS web_net_loss,
    COALESCE(catalog_return_cnt, 0) AS catalog_return_cnt,
    COALESCE(web_return_cnt, 0) AS web_return_cnt,
    (COALESCE(catalog_net_loss, 0) + COALESCE(web_net_loss, 0)) AS total_net_loss,
    RANK() OVER (ORDER BY (COALESCE(catalog_net_loss, 0) + COALESCE(web_net_loss, 0)) DESC) AS state_rank
FROM catalog_agg ca
FULL OUTER JOIN web_agg wa ON ca.state = wa.state
ORDER BY total_net_loss DESC
LIMIT 5
