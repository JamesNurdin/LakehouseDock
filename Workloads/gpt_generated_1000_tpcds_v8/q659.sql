WITH ca_sample AS (
    SELECT ca_address_sk, ca_state
    FROM customer_address
    TABLESAMPLE BERNOULLI (10)
),
catalog_agg AS (
    SELECT
        cp.cp_department,
        cp.cp_type,
        cr.cr_returning_addr_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ca_sample ca ON cr.cr_returning_addr_sk = ca.ca_address_sk
    WHERE cr.cr_return_amount > (
        SELECT AVG(cr2.cr_return_amount)
        FROM catalog_returns cr2
    )
    GROUP BY ROLLUP (cp.cp_department, cp.cp_type, cr.cr_returning_addr_sk)
),
web_agg AS (
    SELECT
        CAST(NULL AS varchar) AS cp_department,
        CAST(NULL AS varchar) AS cp_type,
        wr.wr_returning_addr_sk AS cr_returning_addr_sk,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN ca_sample ca ON wr.wr_returning_addr_sk = ca.ca_address_sk
    WHERE wr.wr_return_amt > (
        SELECT AVG(wr2.wr_return_amt)
        FROM web_returns wr2
    )
    GROUP BY ROLLUP (wr.wr_returning_addr_sk)
),
union_data AS (
    SELECT cp_department, cp_type, cr_returning_addr_sk, total_return_amount, return_cnt
    FROM catalog_agg
    UNION DISTINCT
    SELECT cp_department, cp_type, cr_returning_addr_sk, total_return_amount, return_cnt
    FROM web_agg
),
intersect_keys AS (
    SELECT cr_returning_addr_sk
    FROM catalog_returns
    INTERSECT
    SELECT wr_returning_addr_sk
    FROM web_returns
)
SELECT
    ud.cp_department,
    ud.cp_type,
    ud.cr_returning_addr_sk,
    ud.total_return_amount,
    ud.return_cnt,
    (
        SELECT MAX(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_returning_addr_sk = ud.cr_returning_addr_sk
    ) AS max_return_amount_for_addr,
    ROW_NUMBER() OVER (ORDER BY ud.total_return_amount DESC) AS overall_rank
FROM union_data ud
WHERE ud.cr_returning_addr_sk IN (
    SELECT cr_returning_addr_sk FROM intersect_keys
)
ORDER BY ud.total_return_amount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
