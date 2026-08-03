WITH sales_returns_full AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_ext_sales_price,
        sr.sr_return_amt,
        ss.ss_net_paid_inc_tax,
        COALESCE(ss.ss_ext_sales_price, 0) - COALESCE(sr.sr_return_amt, 0) AS net_amount
    FROM store_sales ss
    FULL OUTER JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
    WHERE (ss.ss_ext_sales_price > 1000 OR sr.sr_return_amt > 500)
)
SELECT store_id,
       net_amount,
       rn,
       category
FROM (
    SELECT
        s.s_store_id AS store_id,
        sr.net_amount,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY sr.net_amount DESC) AS rn,
        'POSITIVE' AS category
    FROM sales_returns_full sr
    JOIN store s
        ON sr.ss_store_sk = s.s_store_sk
    WHERE sr.net_amount > 0

    UNION ALL

    SELECT
        s.s_store_id AS store_id,
        sr.net_amount,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY sr.net_amount ASC) AS rn,
        'NEGATIVE' AS category
    FROM sales_returns_full sr
    JOIN store s
        ON sr.ss_store_sk = s.s_store_sk
    WHERE sr.net_amount <= 0
) combined
WHERE rn <= 5
ORDER BY store_id, rn
LIMIT 100
