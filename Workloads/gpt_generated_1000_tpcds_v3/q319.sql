WITH store_yearly AS (
    SELECT
        store.s_store_id,
        date_dim.d_year,
        SUM(store_returns.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count,
        AVG(store_returns.sr_return_tax) AS avg_return_tax,
        (SELECT MAX(sr2.sr_return_amt)
         FROM store_returns sr2
         WHERE sr2.sr_store_sk = store.s_store_sk) AS max_return_amt_for_store
    FROM store_returns
    JOIN date_dim
        ON store_returns.sr_returned_date_sk = date_dim.d_date_sk
    JOIN store
        ON store_returns.sr_store_sk = store.s_store_sk
    JOIN customer
        ON store_returns.sr_customer_sk = customer.c_customer_sk
    JOIN customer_address
        ON store_returns.sr_addr_sk = customer_address.ca_address_sk
    WHERE date_dim.d_year BETWEEN 1999 AND 2000
      AND store.s_state = 'CA'
      AND store_returns.sr_return_tax > 20
      AND customer.c_birth_month IN (1,5,12)
    GROUP BY store.s_store_id, date_dim.d_year, store.s_store_sk
)
SELECT
    d_year,
    AVG(total_net_loss) AS avg_total_net_loss,
    SUM(return_count) AS total_returns,
    MAX(max_return_amt_for_store) AS max_return_amt_across_stores
FROM store_yearly
GROUP BY d_year
HAVING AVG(total_net_loss) > 1000
ORDER BY d_year DESC
LIMIT 100
