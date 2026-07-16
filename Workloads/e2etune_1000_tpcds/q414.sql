WITH agg AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(*) AS return_count,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_return_amt) AS total_return_amount,
        AVG(sr.sr_return_ship_cost) AS avg_ship_cost,
        SUM(sr.sr_refunded_cash) / NULLIF(SUM(sr.sr_return_amt), 0) AS refund_rate
    FROM store_returns sr
    JOIN customer_demographics cd
      ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2458849 AND 2459214
      AND sr.sr_return_quantity > 0
    GROUP BY cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
    HAVING SUM(sr.sr_net_loss) > (SELECT AVG(cc_tax_percentage) FROM call_center WHERE cc_state = 'CA') * 1000
)
SELECT
    cd_gender,
    cd_marital_status,
    cd_education_status,
    return_count,
    distinct_tickets,
    total_net_loss,
    total_return_amount,
    avg_ship_cost,
    refund_rate,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank,
    SUM(total_net_loss) OVER () AS total_net_loss_all_groups
FROM agg
ORDER BY total_net_loss DESC
LIMIT 10
