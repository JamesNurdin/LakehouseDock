WITH period_one AS (
    SELECT
        st.s_market_desc AS market_desc,
        rs.r_reason_desc AS reason_desc,
        SUM(sr.sr_net_loss) AS net_loss,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers
    FROM tpcds.store_returns sr
    JOIN tpcds.store st ON sr.sr_store_sk = st.s_store_sk
    JOIN tpcds.customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN tpcds.reason rs ON sr.sr_reason_sk = rs.r_reason_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2451000 AND 2451050
    GROUP BY st.s_market_desc, rs.r_reason_desc
),
period_two AS (
    SELECT
        st.s_market_desc AS market_desc,
        rs.r_reason_desc AS reason_desc,
        SUM(sr.sr_net_loss) AS net_loss,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers
    FROM tpcds.store_returns sr
    JOIN tpcds.store st ON sr.sr_store_sk = st.s_store_sk
    JOIN tpcds.customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN tpcds.reason rs ON sr.sr_reason_sk = rs.r_reason_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2451051 AND 2451100
    GROUP BY st.s_market_desc, rs.r_reason_desc
)
SELECT
    market_desc,
    reason_desc,
    SUM(net_loss) AS total_net_loss,
    SUM(distinct_customers) AS total_distinct_customers
FROM (
    SELECT * FROM period_one
    UNION ALL
    SELECT * FROM period_two
) u
GROUP BY ROLLUP(market_desc, reason_desc)
ORDER BY total_net_loss DESC
LIMIT 100
