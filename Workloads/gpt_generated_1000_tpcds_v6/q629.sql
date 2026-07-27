WITH store_ret AS (
    SELECT
        c.c_customer_sk AS customer_sk,
        c.c_first_name,
        c.c_last_name,
        sr.sr_net_loss AS net_loss
    FROM tpcds.store_returns sr
    JOIN tpcds.customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN tpcds.household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE hd.hd_vehicle_count >= 2
      AND c.c_last_review_date > 2452400
),
web_ret AS (
    SELECT
        c.c_customer_sk AS customer_sk,
        c.c_first_name,
        c.c_last_name,
        wr.wr_net_loss AS net_loss
    FROM tpcds.web_returns wr
    JOIN tpcds.customer c
        ON wr.wr_returning_customer_sk = c.c_customer_sk
    JOIN tpcds.household_demographics hd
        ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.customer_address ca
        ON wr.wr_returning_addr_sk = ca.ca_address_sk
    WHERE hd.hd_vehicle_count >= 2
      AND c.c_last_review_date > 2452400
)
SELECT
    t.customer_sk,
    t.c_first_name,
    t.c_last_name,
    SUM(t.net_loss) AS total_net_loss,
    COUNT(*) AS return_count
FROM (
    SELECT customer_sk, c_first_name, c_last_name, net_loss FROM store_ret
    UNION ALL
    SELECT customer_sk, c_first_name, c_last_name, net_loss FROM web_ret
) t
GROUP BY t.customer_sk, t.c_first_name, t.c_last_name
HAVING SUM(t.net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
