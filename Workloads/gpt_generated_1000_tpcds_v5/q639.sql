/*
  Goal: Compare total return amounts by item category, department (when available), and hour of day for catalog returns versus store returns, and list the top 100 rows ordered by the highest total return amount.
*/
WITH catalog_ret AS (
    SELECT
        i.i_category AS category,
        cp.cp_department AS department,
        td.t_hour AS hour_of_day,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        'Catalog' AS source_type
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE cr.cr_return_amount > 0
    GROUP BY i.i_category, cp.cp_department, td.t_hour
),
store_ret AS (
    SELECT
        i.i_category AS category,
        CAST(NULL AS varchar) AS department,
        td.t_hour AS hour_of_day,
        SUM(sr.sr_return_amt) AS total_return_amount,
        COUNT(*) AS return_cnt,
        'Store' AS source_type
    FROM store_returns sr
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN time_dim td
        ON sr.sr_return_time_sk = td.t_time_sk
    WHERE sr.sr_return_amt > 0
    GROUP BY i.i_category, td.t_hour
)
SELECT
    category,
    department,
    hour_of_day,
    total_return_amount,
    return_cnt,
    source_type
FROM catalog_ret
UNION ALL
SELECT
    category,
    department,
    hour_of_day,
    total_return_amount,
    return_cnt,
    source_type
FROM store_ret
ORDER BY total_return_amount DESC
LIMIT 100
