WITH base AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_addr_sk,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_store_credit,
        st.s_store_name,
        st.s_tax_percentage,
        ca.ca_city,
        ca.ca_gmt_offset,
        ca.ca_suite_number,
        CASE WHEN sr.sr_store_credit > 100 THEN 'High Credit' ELSE 'Low Credit' END AS credit_category
    FROM tpcds.store_returns AS sr
    FULL OUTER JOIN tpcds.store AS st
        ON sr.sr_store_sk = st.s_store_sk
    LEFT JOIN tpcds.customer_address AS ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE
        ca.ca_gmt_offset = -5.00
        AND ca.ca_suite_number = 'Suite 70'
        AND st.s_tax_percentage BETWEEN 5.00 AND 8.00
        AND NOT EXISTS (
            SELECT 1
            FROM tpcds.store_returns AS sr2
            WHERE sr2.sr_store_sk = st.s_store_sk
              AND sr2.sr_return_amt > 5000
        )
)
SELECT
    base.s_store_name,
    base.ca_city,
    base.credit_category,
    COUNT(*) AS return_cnt,
    SUM(base.sr_return_amt) AS total_return_amt,
    AVG(base.sr_return_tax) AS avg_return_tax,
    MIN(base.sr_store_credit) AS min_store_credit,
    MAX(base.sr_store_credit) AS max_store_credit
FROM base
GROUP BY
    base.s_store_name,
    base.ca_city,
    base.credit_category
ORDER BY total_return_amt DESC
LIMIT 100
