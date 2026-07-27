WITH sales_returns AS (
    SELECT
        s.s_store_id AS store_id,
        t.t_hour AS hour,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(cr.cr_return_amount) AS total_catalog_returns,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_txn_cnt,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_return_cnt
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE
        t.t_hour BETWEEN 8 AND 18                     -- predicate 1
        AND t.t_minute IN (6, 13, 7)                  -- predicate 2
        AND s.s_company_id = 1                        -- predicate 3
        AND s.s_street_number = '408'                 -- predicate 4
        AND cr.cr_return_quantity > 0                -- predicate 5
        AND ss.ss_quantity >= 1                      -- predicate 6
        AND EXISTS (
            SELECT 1
            FROM web_returns wr
            WHERE wr.wr_returned_time_sk = t.t_time_sk
              AND wr.wr_return_ship_cost > 100        -- predicate 7 (inside subquery)
              AND wr.wr_item_sk = ss.ss_item_sk
        )
    GROUP BY s.s_store_id, t.t_hour
),
store_summary AS (
    SELECT
        store_id,
        SUM(total_sales) AS sum_sales,
        SUM(total_catalog_returns) AS sum_returns,
        SUM(sales_txn_cnt) AS sum_txn,
        SUM(catalog_return_cnt) AS sum_ret_cnt
    FROM sales_returns
    GROUP BY store_id
)
SELECT
    store_id,
    sum_sales,
    sum_returns,
    sum_sales - sum_returns AS net_revenue,
    sum_txn,
    sum_ret_cnt,
    (sum_sales - sum_returns) / NULLIF(sum_txn, 0) AS avg_net_per_txn
FROM store_summary
WHERE (sum_sales - sum_returns) > 5000               -- final filter
ORDER BY net_revenue DESC
LIMIT 100
