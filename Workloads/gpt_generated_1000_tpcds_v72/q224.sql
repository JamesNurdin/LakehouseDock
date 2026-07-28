WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_catalog_page_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_fee,
        cr.cr_net_loss,
        cr.cr_refunded_cash,
        cr.cr_store_credit
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 100.00                                 -- filter 1
      AND cr.cr_fee BETWEEN 5.00 AND 100.00                               -- filter 2
      AND cr.cr_return_quantity >= 1                                      -- filter 3
      AND cr.cr_returned_date_sk IN (
            SELECT d_date_sk
            FROM date_dim
            WHERE d_quarter_name = '1901Q1'                          -- filter 4
              AND d_weekend = 'N'                                      -- filter 5
        )
      AND cr.cr_refunded_cash > 50.00                                    -- filter 6
),
agg_returns AS (
    SELECT
        s.s_store_id,
        s.s_manager,
        cp.cp_department,
        d_ret.d_year,
        COUNT(*) AS total_returns,
        SUM(fr.cr_return_amount) AS sum_return_amount,
        AVG(fr.cr_return_amount) AS avg_return_amount,
        MIN(fr.cr_return_amount) AS min_return_amount,
        MAX(fr.cr_return_amount) AS max_return_amount
    FROM filtered_returns fr
    JOIN catalog_page cp
        ON fr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_ret
        ON fr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    WHERE cp.cp_department IN ('Books', 'Electronics', 'Home')          -- filter 7
      AND cp.cp_type = 'Standard'                                         -- filter 8
      AND s.s_state = 'CA'                                                -- filter 9
      AND s.s_manager NOT IN ('Jerry Brooks')                             -- filter 10
      AND d_ret.d_year BETWEEN 1999 AND 2001                              -- filter 11
      AND EXISTS (
            SELECT 1
            FROM catalog_page cp2
            WHERE cp2.cp_catalog_page_sk = cp.cp_catalog_page_sk
              AND cp2.cp_description LIKE '%Catalog%'
        )                                                               -- subquery filter
      AND NOT EXISTS (
            SELECT 1
            FROM catalog_returns cr2
            WHERE cr2.cr_catalog_page_sk = cp.cp_catalog_page_sk
              AND cr2.cr_return_amount > 5000
        )                                                               -- anti‑join filter
    GROUP BY
        s.s_store_id,
        s.s_manager,
        cp.cp_department,
        d_ret.d_year
)
SELECT
    a.s_store_id,
    a.s_manager,
    a.cp_department,
    a.d_year,
    a.total_returns,
    a.sum_return_amount,
    a.avg_return_amount,
    a.min_return_amount,
    a.max_return_amount,
    SUM(a.sum_return_amount) OVER (
        PARTITION BY a.s_store_id
        ORDER BY a.d_year
        ROWS UNBOUNDED PRECEDING
    ) AS cumulative_return_amount,
    RANK() OVER (
        PARTITION BY a.s_store_id
        ORDER BY a.sum_return_amount DESC
    ) AS dept_rank
FROM agg_returns a
ORDER BY a.sum_return_amount DESC, a.total_returns DESC
LIMIT 100
