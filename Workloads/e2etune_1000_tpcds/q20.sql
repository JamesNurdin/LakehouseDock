WITH filtered_returns AS (
    SELECT sr.sr_returned_date_sk,
           sr.sr_return_amt,
           sr.sr_net_loss,
           sr.sr_hdemo_sk,
           sr.sr_addr_sk,
           sr.sr_return_quantity,
           sr.sr_fee,
           sr.sr_refunded_cash,
           sr.sr_store_credit
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk BETWEEN 2450800 AND 2450900
      AND sr.sr_net_loss > 0
),
agg_returns AS (
    SELECT
        ca.ca_state,
        ca.ca_city,
        hd.hd_buy_potential,
        hd.hd_income_band_sk,
        COUNT(*) AS total_returns,
        SUM(fr.sr_net_loss) AS total_net_loss,
        AVG(fr.sr_return_amt) AS avg_return_amount,
        SUM(fr.sr_return_quantity) AS total_return_qty
    FROM filtered_returns fr
    JOIN household_demographics hd ON fr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON fr.sr_addr_sk = ca.ca_address_sk
    WHERE hd.hd_buy_potential IN ('HIGH', 'MEDIUM')
      AND ca.ca_country = 'United States'
    GROUP BY ca.ca_state, ca.ca_city, hd.hd_buy_potential, hd.hd_income_band_sk
    HAVING COUNT(*) >= 5
)
SELECT
    ca_state,
    ca_city,
    hd_buy_potential,
    hd_income_band_sk,
    total_returns,
    total_net_loss,
    avg_return_amount,
    total_return_qty,
    RANK() OVER (PARTITION BY ca_state ORDER BY total_net_loss DESC) AS loss_rank_state,
    ROW_NUMBER() OVER (ORDER BY total_net_loss DESC) AS overall_loss_rank
FROM agg_returns
ORDER BY total_net_loss DESC
LIMIT 100
