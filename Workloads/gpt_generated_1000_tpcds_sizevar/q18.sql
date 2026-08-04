WITH agg1 AS (
    SELECT
        s.s_store_id,
        s.s_state,
        cd.cd_credit_rating,
        hd.hd_buy_potential,
        SUM(cr.cr_return_amount) AS catalog_return_sum,
        SUM(sr.sr_return_amt) AS store_return_sum,
        SUM(cr.cr_net_loss + sr.sr_net_loss) AS total_net_loss,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_tickets
    FROM catalog_returns cr
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN store_returns sr
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    WHERE cr.cr_return_amount > 100
      AND cr.cr_reason_sk IN (1, 2, 3)
      AND cd.cd_credit_rating = 'Low Risk'
      AND hd.hd_buy_potential = '1001-5000'
      AND s.s_state = 'CA'
      AND hd.hd_dep_count >= 2
      AND cd.cd_dep_college_count <= 4
    GROUP BY s.s_store_id, s.s_state, cd.cd_credit_rating, hd.hd_buy_potential
)
SELECT
    a.s_store_id,
    a.s_state,
    a.cd_credit_rating,
    a.hd_buy_potential,
    a.catalog_return_sum,
    a.store_return_sum,
    a.total_net_loss,
    a.catalog_orders,
    a.store_tickets,
    ROW_NUMBER() OVER (ORDER BY a.total_net_loss DESC) AS rn
FROM agg1 a
WHERE a.total_net_loss > 0
ORDER BY a.total_net_loss DESC
LIMIT 100
