WITH unified AS (
    SELECT
        s.s_state AS state,
        sr.sr_customer_sk AS customer_sk,
        sr.sr_item_sk AS item_sk,
        sr.sr_return_amt,
        ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY sr.sr_return_amt DESC) AS rn_state,
        CASE WHEN sr.sr_return_tax > 30 THEN 'HighTax' ELSE 'LowTax' END AS tax_category
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    WHERE sr.sr_return_amt > 100
        AND sr.sr_fee BETWEEN 10 AND 80
        AND sr.sr_reversed_charge < 500
        AND s.s_state IN ('CA', 'TX', 'NY')
        AND s.s_country = 'United States'
        AND s.s_hours LIKE '%8AM-%'
        AND s.s_gmt_offset >= -5

    UNION

    SELECT
        s.s_state AS state,
        sr.sr_customer_sk AS customer_sk,
        sr.sr_item_sk AS item_sk,
        sr.sr_return_amt,
        ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY sr.sr_return_amt DESC) AS rn_state,
        CASE WHEN sr.sr_return_tax > 30 THEN 'HighTax' ELSE 'LowTax' END AS tax_category
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    WHERE sr.sr_return_amt BETWEEN 50 AND 150
        AND sr.sr_fee > 20
        AND sr.sr_reversed_charge BETWEEN 0 AND 200
        AND s.s_state NOT IN ('FL', 'WA')
        AND s.s_country = 'United States'
        AND s.s_hours LIKE '%8AM-4PM%'
        AND s.s_gmt_offset < 0
)
SELECT
    state,
    COUNT(DISTINCT customer_sk) AS uniq_customers,
    COUNT(DISTINCT item_sk) AS uniq_items,
    SUM(sr_return_amt) AS total_return_amt,
    MAX(rn_state) AS max_return_rank
FROM unified
GROUP BY state
ORDER BY total_return_amt DESC
