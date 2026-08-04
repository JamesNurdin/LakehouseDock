/*
Goal: Identify the top‑performing brand‑category combinations based on total return amount, categorizing returns as High or Low, and filter to only those segments with above‑average net loss.
*/
WITH filtered AS (
    SELECT
        sr.sr_customer_sk,
        sr.sr_item_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_net_loss,
        i.i_brand,
        i.i_category,
        i.i_manager_id,
        c.c_current_addr_sk,
        c.c_first_sales_date_sk,
        CASE WHEN sr.sr_return_amt > 100 THEN 'High' ELSE 'Low' END AS return_level
    FROM
        store_returns sr
        TABLESAMPLE BERNOULLI (10)   -- sample 10% of store_returns
        JOIN item i
            ON sr.sr_item_sk = i.i_item_sk
        JOIN customer c
            ON sr.sr_customer_sk = c.c_customer_sk
    WHERE
        sr.sr_return_quantity > 1                         -- predicate 1
        AND sr.sr_return_amt IS NOT NULL                  -- predicate 2
        AND i.i_manager_id IN (19, 23, 44)                -- predicate 3
        AND i.i_rec_start_date >= DATE '1999-01-01'       -- predicate 4
        AND c.c_current_addr_sk BETWEEN 1000000 AND 5000000 -- predicate 5
        AND c.c_first_sales_date_sk >= 2450000            -- predicate 6
),
agg1 AS (
    SELECT
        i_brand,
        i_category,
        return_level,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(DISTINCT sr_customer_sk) AS distinct_customers,
        COUNT(DISTINCT sr_return_quantity) AS distinct_quantities,
        AVG(sr_net_loss) AS avg_net_loss
    FROM filtered
    GROUP BY i_brand, i_category, return_level
)
SELECT
    a.i_brand,
    a.i_category,
    a.return_level,
    a.total_return_amt,
    a.distinct_customers,
    a.distinct_quantities,
    a.avg_net_loss,
    CASE
        WHEN a.total_return_amt > (SELECT MAX(total_return_amt) FROM agg1) THEN 'TopBrand'
        ELSE 'Other'
    END AS brand_rank
FROM agg1 a
WHERE a.avg_net_loss > (SELECT AVG(avg_net_loss) FROM agg1)
ORDER BY a.total_return_amt DESC
LIMIT 100
