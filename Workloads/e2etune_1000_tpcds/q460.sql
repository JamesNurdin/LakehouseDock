WITH aggregated AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        cd.cd_education_status,
        cd.cd_marital_status,
        COUNT(DISTINCT sr.sr_ticket_number) AS num_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr.sr_return_ship_cost) AS total_ship_cost,
        SUM(sr.sr_fee) AS total_fee,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_return_quantity) AS avg_return_qty
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450000 AND 2450300
      AND cd.cd_purchase_estimate >= 1500
      AND s.s_state = 'CA'
    GROUP BY s.s_store_id, s.s_store_name, cd.cd_education_status, cd.cd_marital_status
    HAVING SUM(sr.sr_net_loss) > 0
)
SELECT
    a.s_store_id,
    a.s_store_name,
    a.cd_education_status,
    a.cd_marital_status,
    a.num_returns,
    a.total_return_amount,
    a.total_ship_cost,
    a.total_fee,
    a.total_net_loss,
    a.avg_return_qty,
    RANK() OVER (PARTITION BY a.cd_education_status ORDER BY a.total_net_loss DESC) AS loss_rank_by_education
FROM aggregated a
ORDER BY a.total_net_loss DESC
LIMIT 100
