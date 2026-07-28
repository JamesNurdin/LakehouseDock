WITH date_year AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_year BETWEEN 2001 AND 2003
),
catalog_part AS (
    SELECT
        r.r_reason_desc AS reason,
        dy.d_year AS year,
        cr.cr_return_amount AS return_amount
    FROM catalog_returns cr
    JOIN date_year dy ON cr.cr_returned_date_sk = dy.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_quantity > 0
      AND EXISTS (
          SELECT 1 FROM item i
          WHERE i.i_item_sk = cr.cr_item_sk
            AND i.i_current_price > 100
      )
),
web_part AS (
    SELECT
        r.r_reason_desc AS reason,
        dy.d_year AS year,
        wr.wr_return_amt AS return_amount
    FROM web_returns wr
    JOIN date_year dy ON wr.wr_returned_date_sk = dy.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_return_quantity > 0
      AND EXISTS (
          SELECT 1 FROM item i
          WHERE i.i_item_sk = wr.wr_item_sk
            AND i.i_current_price > 100
      )
)
SELECT
    COALESCE(reason, 'All Reasons') AS reason,
    COALESCE(year, 0) AS year,
    SUM(total_return_amount) AS combined_total
FROM (
    SELECT reason, year, SUM(return_amount) AS total_return_amount
    FROM (
        SELECT DISTINCT reason, year, return_amount
        FROM catalog_part
        UNION ALL
        SELECT DISTINCT reason, year, return_amount
        FROM web_part
    ) u
    GROUP BY reason, year
) agg
GROUP BY GROUPING SETS (
    (reason, year),
    (reason),
    (year),
    ()
)
HAVING SUM(total_return_amount) > (
    SELECT AVG(inner_total)
    FROM (
        SELECT SUM(return_amount) AS inner_total
        FROM (
            SELECT DISTINCT reason, year, return_amount
            FROM catalog_part
            UNION ALL
            SELECT DISTINCT reason, year, return_amount
            FROM web_part
        ) q
        GROUP BY reason, year
    ) avg_tbl
)
ORDER BY combined_total DESC
LIMIT 100
