WITH base AS (
    SELECT
        ca.ca_state,
        d.d_year,
        d.d_month_seq,
        sr.sr_return_amt,
        sr.sr_net_loss,
        sr.sr_return_ship_cost
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2002
      AND ca.ca_state IN ('TX', 'CA')
      AND sr.sr_return_ship_cost > 50
),
monthly_state AS (
    SELECT
        ca_state,
        d_year,
        d_month_seq,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM base
    GROUP BY ca_state, d_year, d_month_seq
)
SELECT
    ca_state,
    AVG(total_net_loss) AS avg_monthly_net_loss,
    SUM(total_return_amt) AS sum_return_amt_over_year,
    COUNT(*) AS months_with_returns
FROM monthly_state
GROUP BY ca_state
HAVING AVG(total_net_loss) > 1000
ORDER BY avg_monthly_net_loss DESC
