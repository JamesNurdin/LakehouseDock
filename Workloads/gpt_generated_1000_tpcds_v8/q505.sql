WITH
    sampled_returns AS (
        SELECT
            wr_returned_date_sk,
            wr_returned_time_sk,
            wr_item_sk,
            wr_refunded_customer_sk,
            wr_refunded_cdemo_sk,
            wr_refunded_hdemo_sk,
            wr_refunded_addr_sk,
            wr_returning_customer_sk,
            wr_returning_cdemo_sk,
            wr_returning_hdemo_sk,
            wr_returning_addr_sk,
            wr_web_page_sk,
            wr_reason_sk,
            wr_order_number,
            wr_return_quantity,
            wr_return_amt,
            wr_return_tax,
            wr_return_amt_inc_tax,
            wr_fee,
            wr_return_ship_cost,
            wr_refunded_cash,
            wr_reversed_charge,
            wr_account_credit,
            wr_net_loss
        FROM web_returns
        TABLESAMPLE BERNOULLI (10)
        WHERE wr_return_amt IS NOT NULL
    ),
    refunded_addr AS (
        SELECT
            ca.ca_address_sk,
            ca.ca_city,
            ca.ca_state,
            SUM(wr.wr_return_amt) AS total_refunded_amt,
            COUNT(*) AS cnt_refunded,
            ROW_NUMBER() OVER (PARTITION BY ca.ca_address_sk ORDER BY SUM(wr.wr_return_amt) DESC) AS rn_refunded
        FROM sampled_returns wr
        JOIN customer_address ca
            ON wr.wr_refunded_addr_sk = ca.ca_address_sk
        GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state
    ),
    returning_addr AS (
        SELECT
            ca.ca_address_sk,
            ca.ca_city,
            ca.ca_state,
            SUM(wr.wr_return_amt) AS total_returning_amt,
            COUNT(*) AS cnt_returning,
            ROW_NUMBER() OVER (PARTITION BY ca.ca_address_sk ORDER BY SUM(wr.wr_return_amt) DESC) AS rn_returning
        FROM sampled_returns wr
        JOIN customer_address ca
            ON wr.wr_returning_addr_sk = ca.ca_address_sk
        GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state
    ),
    common_addrs AS (
        SELECT ca_address_sk FROM refunded_addr
        INTERSECT
        SELECT ca_address_sk FROM returning_addr
    ),
    select_refunded AS (
        SELECT
            ra.ca_address_sk,
            ra.ca_city,
            ra.ca_state,
            ra.total_refunded_amt AS total_return_amt,
            'refunded' AS addr_role,
            ROW_NUMBER() OVER (PARTITION BY ra.ca_address_sk ORDER BY ra.total_refunded_amt DESC) AS rn_role
        FROM refunded_addr ra
        WHERE ra.ca_address_sk IN (SELECT ca_address_sk FROM common_addrs)
    ),
    select_returning AS (
        SELECT
            ra.ca_address_sk,
            ra.ca_city,
            ra.ca_state,
            ra.total_returning_amt AS total_return_amt,
            'returning' AS addr_role,
            ROW_NUMBER() OVER (PARTITION BY ra.ca_address_sk ORDER BY ra.total_returning_amt DESC) AS rn_role
        FROM returning_addr ra
        WHERE NOT EXISTS (
            SELECT 1 FROM common_addrs ca WHERE ca.ca_address_sk = ra.ca_address_sk
        )
    )
SELECT
    combined.ca_address_sk,
    combined.ca_city,
    combined.ca_state,
    combined.total_return_amt,
    combined.addr_role,
    combined.rn_role,
    (SELECT AVG(wr_return_amt) FROM sampled_returns) AS overall_avg_return_amt
FROM (
    SELECT ca_address_sk, ca_city, ca_state, total_return_amt, addr_role, rn_role
    FROM select_refunded
    UNION
    SELECT ca_address_sk, ca_city, ca_state, total_return_amt, addr_role, rn_role
    FROM select_returning
) AS combined
WHERE combined.rn_role = 1
ORDER BY combined.total_return_amt DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
