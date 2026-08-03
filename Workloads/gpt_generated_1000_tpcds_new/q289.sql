WITH store_agg AS (
    SELECT
        sr_addr_sk,
        sr_reason_sk,
        SUM(sr_net_loss) AS total_net_loss,
        COUNT(*) AS store_return_cnt
    FROM store_returns
    GROUP BY sr_addr_sk, sr_reason_sk
),
joined AS (
    SELECT
        ca.ca_state,
        ca.ca_city,
        ca.ca_zip,
        ca.ca_location_type,
        r.r_reason_desc,
        sa.total_net_loss,
        sa.store_return_cnt,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        wr.wr_returned_date_sk
    FROM store_agg sa
    JOIN customer_address ca
        ON sa.sr_addr_sk = ca.ca_address_sk
    JOIN reason r
        ON sa.sr_reason_sk = r.r_reason_sk
    JOIN web_returns wr
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
        AND wr.wr_reason_sk = r.r_reason_sk
    WHERE ca.ca_state = 'TX'
      AND ca.ca_location_type = 'single family'
      AND ca.ca_zip LIKE '75%'
      AND r.r_reason_desc LIKE '%price%'
      AND sa.total_net_loss > 1000
      AND wr.wr_return_amt > 50
      AND wr.wr_return_quantity >= 2
),
agg AS (
    SELECT
        ca_state,
        r_reason_desc,
        SUM(total_net_loss) AS sum_net_loss,
        SUM(store_return_cnt) AS sum_store_returns,
        SUM(wr_return_amt) AS sum_web_return_amt,
        COUNT(*) AS transaction_cnt
    FROM joined
    GROUP BY GROUPING SETS (
        (ca_state, r_reason_desc),
        (ca_state),
        (r_reason_desc),
        ()
    )
    HAVING SUM(total_net_loss) > 2000
)
SELECT
    ca_state,
    r_reason_desc,
    sum_net_loss,
    sum_store_returns,
    sum_web_return_amt,
    transaction_cnt,
    RANK() OVER (PARTITION BY ca_state ORDER BY sum_net_loss DESC) AS state_net_loss_rank
FROM agg
ORDER BY sum_net_loss DESC
LIMIT 100
