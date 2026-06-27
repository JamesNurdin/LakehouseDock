WITH state_returns AS (
    SELECT
        ca.ca_state,
        hd.hd_buy_potential,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(sr.sr_return_quantity) AS avg_return_quantity
    FROM store_returns sr
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE ca.ca_country = 'United States'
    GROUP BY ca.ca_state, hd.hd_buy_potential
)

SELECT
    sr.ca_state,
    sr.hd_buy_potential,
    sr.total_return_amt,
    sr.total_net_loss,
    sr.return_cnt,
    sr.avg_return_quantity,
    RANK() OVER (PARTITION BY sr.hd_buy_potential ORDER BY sr.total_return_amt DESC) AS state_return_rank
FROM state_returns sr
ORDER BY sr.hd_buy_potential, state_return_rank
LIMIT 100
