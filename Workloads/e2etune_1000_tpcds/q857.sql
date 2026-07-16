WITH agg AS (
    SELECT
        r.r_reason_desc,
        ca_ref.ca_state AS refund_state,
        cd_ref.cd_gender AS refund_gender,
        COUNT(*) AS num_returns,
        COUNT(DISTINCT cr.cr_returning_customer_sk) AS distinct_returning_customers,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_fee) AS avg_fee,
        SUM(cr.cr_return_quantity) AS total_quantity,
        SUM(cr.cr_return_ship_cost) AS total_ship_cost
    FROM catalog_returns cr
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_address ca_ref
        ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_address ca_ret
        ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN customer_demographics cd_ref
        ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN customer_demographics cd_ret
        ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    WHERE cr.cr_warehouse_sk = 10
      AND cr.cr_fee > 30
      AND ca_ref.ca_country = 'United States'
      AND cd_ref.cd_gender = 'F'
    GROUP BY r.r_reason_desc, ca_ref.ca_state, cd_ref.cd_gender
    HAVING SUM(cr.cr_return_quantity) > 50
)
SELECT
    agg.r_reason_desc,
    agg.refund_state,
    agg.refund_gender,
    agg.num_returns,
    agg.distinct_returning_customers,
    agg.total_net_loss,
    agg.avg_fee,
    agg.total_quantity,
    agg.total_ship_cost,
    DENSE_RANK() OVER (PARTITION BY agg.refund_state ORDER BY agg.total_net_loss DESC) AS reason_rank
FROM agg
ORDER BY agg.refund_state, reason_rank
LIMIT 100
