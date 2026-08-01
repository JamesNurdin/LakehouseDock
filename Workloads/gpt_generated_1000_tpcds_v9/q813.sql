WITH
    base AS (
        SELECT
            sr.sr_returned_date_sk,
            d.d_date,
            sr.sr_store_sk,
            s.s_store_name,
            sr.sr_addr_sk,
            ca.ca_city,
            sr.sr_return_amt,
            sr.sr_return_tax,
            sr.sr_refunded_cash,
            inv.inv_quantity_on_hand,
            CASE WHEN sr.sr_return_amt > 1000 THEN 'High' ELSE 'Low' END AS return_category,
            ROW_NUMBER() OVER (PARTITION BY sr.sr_store_sk ORDER BY d.d_date) AS rn_store_date,
            SUM(sr.sr_return_amt) OVER (
                PARTITION BY sr.sr_store_sk
                ORDER BY d.d_date
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS running_return_amt,
            LAG(sr.sr_return_amt) OVER (PARTITION BY sr.sr_store_sk ORDER BY d.d_date) AS prev_return_amt
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
        WHERE d.d_year = 2000
          AND s.s_state = 'TN'
          AND ca.ca_state = 'TN'
          AND sr.sr_return_amt > 0
          AND inv.inv_quantity_on_hand > 0
    ),
    top_returns AS (
        SELECT
            sr_returned_date_sk,
            d_date,
            s_store_name,
            return_category,
            running_return_amt,
            rn_store_date,
            prev_return_amt
        FROM base
        WHERE rn_store_date <= 5
    ),
    low_returns AS (
        SELECT
            sr_returned_date_sk,
            d_date,
            s_store_name,
            return_category,
            running_return_amt,
            rn_store_date,
            prev_return_amt
        FROM base
        WHERE rn_store_date > 5
    ),
    unioned AS (
        SELECT sr_returned_date_sk, d_date, s_store_name, return_category,
               running_return_amt, rn_store_date, prev_return_amt
        FROM top_returns
        UNION ALL
        SELECT sr_returned_date_sk, d_date, s_store_name, return_category,
               running_return_amt, rn_store_date, prev_return_amt
        FROM low_returns
    ),
    excepted AS (
        SELECT sr_returned_date_sk FROM top_returns
        EXCEPT
        SELECT sr_returned_date_sk FROM low_returns
    )
SELECT
    u.sr_returned_date_sk,
    u.d_date,
    u.s_store_name,
    u.return_category,
    u.running_return_amt,
    u.rn_store_date,
    u.prev_return_amt,
    RANK() OVER (ORDER BY u.running_return_amt DESC) AS return_rank
FROM unioned u
WHERE u.sr_returned_date_sk IN (SELECT sr_returned_date_sk FROM excepted)
ORDER BY u.running_return_amt DESC
LIMIT 100
