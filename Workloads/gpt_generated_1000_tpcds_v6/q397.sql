WITH customer_agg AS (
    SELECT
        c.c_customer_id,
        c.c_birth_country,
        cd.cd_gender,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(DISTINCT p.p_promo_name) AS promo_count
    FROM tpcds.customer c
    JOIN tpcds.customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    WHERE c.c_birth_country IN ('SWITZERLAND', 'NICARAGUA')
      AND cd.cd_dep_count <= 3
      AND p.p_channel_press = 'N'
      AND p.p_response_target = 1
      AND ws.ws_quantity > 1
    GROUP BY c.c_customer_id, c.c_birth_country, cd.cd_gender
)
SELECT
    ca.c_customer_id,
    ca.c_birth_country,
    ca.cd_gender,
    ca.total_net_profit,
    ca.total_net_loss,
    ca.promo_count,
    RANK() OVER (ORDER BY ca.total_net_profit DESC) AS profit_rank,
    DENSE_RANK() OVER (ORDER BY ca.total_net_loss DESC) AS loss_rank
FROM customer_agg ca
ORDER BY profit_rank
LIMIT 100
