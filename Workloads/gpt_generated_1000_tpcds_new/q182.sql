WITH sampled_web_page AS (
    SELECT
        wp_web_page_sk,
        wp_url,
        wp_char_count,
        wp_link_count,
        wp_type,
        wp_creation_date_sk
    FROM web_page
    TABLESAMPLE BERNOULLI (20)
    WHERE wp_link_count > 10
      AND wp_type = 'Content'
),
joined_data AS (
    SELECT
        wr.wr_order_number,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        d.d_year,
        t.t_hour,
        r.r_reason_desc,
        inv.inv_quantity_on_hand,
        cp.cp_department,
        wp.wp_url,
        wp.wp_char_count
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cp.cp_end_date_sk = d.d_date_sk
    JOIN sampled_web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
      AND t.t_hour BETWEEN 8 AND 18
      AND r.r_reason_desc LIKE '%product%'
      AND inv.inv_quantity_on_hand > 0
      AND cp.cp_department = 'Home'
      AND wp.wp_char_count < 5000
),
agg_by_year_dept AS (
    SELECT
        d_year,
        cp_department,
        r_reason_desc,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_return_quantity) AS total_return_qty,
        COUNT(DISTINCT wr_order_number) AS orders_cnt
    FROM joined_data
    GROUP BY d_year, cp_department, r_reason_desc
)
SELECT *
FROM (
    SELECT d_year, cp_department, r_reason_desc, total_return_amt, total_return_qty, orders_cnt
    FROM agg_by_year_dept
    WHERE total_return_amt > 5000
) AS high_returns
EXCEPT
SELECT d_year, cp_department, r_reason_desc, total_return_amt, total_return_qty, orders_cnt
FROM agg_by_year_dept
WHERE total_return_qty < 10
ORDER BY total_return_amt DESC
LIMIT 100
