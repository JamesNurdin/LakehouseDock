WITH high_tax_stores AS (
        SELECT s_store_sk
        FROM store
        WHERE s_tax_percentage > 6.00
    ),
    low_tax_stores AS (
        SELECT s_store_sk
        FROM store
        WHERE s_tax_percentage < 2.00
    ),
    target_stores AS (
        SELECT s_store_sk FROM high_tax_stores
        UNION
        SELECT s_store_sk FROM low_tax_stores
    )
SELECT
    store.s_store_id,
    store.s_city,
    CASE
        WHEN store_returns.sr_refunded_cash > (SELECT AVG(sr_refunded_cash) FROM store_returns) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS cash_category,
    COUNT(*) AS return_count,
    SUM(store_returns.sr_return_amt) AS total_return_amt,
    AVG(store_returns.sr_refunded_cash) AS avg_refunded_cash,
    MIN(store_returns.sr_return_tax) AS min_tax,
    MAX(store_returns.sr_return_tax) AS max_tax
FROM store_returns
JOIN customer_address
    ON store_returns.sr_addr_sk = customer_address.ca_address_sk
JOIN store
    ON store_returns.sr_store_sk = store.s_store_sk
WHERE
    store_returns.sr_refunded_cash > 500
    AND store_returns.sr_fee BETWEEN 30 AND 60
    AND customer_address.ca_country = 'United States'
    AND customer_address.ca_street_type IN ('Ln', 'Blvd', 'Boulevard')
    AND store.s_tax_percentage < 5.00
    AND store_returns.sr_returned_date_sk BETWEEN 2450000 AND 2450100
    AND EXISTS (
        SELECT 1
        FROM store s2
        WHERE s2.s_store_sk = store_returns.sr_store_sk
          AND s2.s_company_id = 1
          AND s2.s_company_name = 'Unknown'
    )
    AND store_returns.sr_store_sk IN (SELECT s_store_sk FROM target_stores)
GROUP BY
    store.s_store_id,
    store.s_city,
    CASE
        WHEN store_returns.sr_refunded_cash > (SELECT AVG(sr_refunded_cash) FROM store_returns) THEN 'Above Avg'
        ELSE 'Below Avg'
    END
ORDER BY total_return_amt DESC
LIMIT 100
