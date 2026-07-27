WITH base AS (
    SELECT
        cp.cp_department,
        cp.cp_catalog_page_number,
        cr.cr_returned_date_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        wr.wr_returned_date_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss,
        td.t_meal_time,
        td.t_shift,
        CASE
            WHEN cr.cr_return_amount > 100 THEN 'high'
            WHEN cr.cr_return_amount > 50 THEN 'medium'
            ELSE 'low'
        END AS return_amount_category
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN web_returns wr
        ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE cp.cp_department = 'Electronics'
      AND td.t_meal_time = 'lunch'
      AND cr.cr_return_quantity > 1
)
SELECT
    cp_department,
    cp_catalog_page_number,
    return_amount_category,
    total_return_amount,
    total_web_return_amount,
    txn_count,
    ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY total_return_amount DESC) AS dept_rank,
    SUM(total_return_amount) OVER (PARTITION BY return_amount_category ORDER BY cp_catalog_page_number ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_return_by_category
FROM (
    SELECT
        cp_department,
        cp_catalog_page_number,
        return_amount_category,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(wr_return_amt) AS total_web_return_amount,
        COUNT(*) AS txn_count
    FROM base
    GROUP BY cp_department, cp_catalog_page_number, return_amount_category
) agg
ORDER BY total_return_amount DESC
LIMIT 100
