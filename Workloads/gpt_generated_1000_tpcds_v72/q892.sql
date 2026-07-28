WITH
    -- Scalar subqueries are used directly in the CASE expressions below
    
    -- First sub‑query for catalog returns
    catalog_returns_agg AS (
        SELECT
            d.d_year AS year,
            r.r_reason_desc AS reason,
            SUM(cr.cr_return_amount) AS total_return_amount,
            CASE
                WHEN SUM(cr.cr_return_amount) > (SELECT AVG(cr2.cr_return_amount) FROM catalog_returns cr2)
                THEN 'HIGH'
                ELSE 'NORMAL'
            END AS return_category
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        WHERE d.d_year BETWEEN 2000 AND 2002
        GROUP BY d.d_year, r.r_reason_desc
    ),

    -- Second sub‑query for web returns
    web_returns_agg AS (
        SELECT
            d.d_year AS year,
            r.r_reason_desc AS reason,
            SUM(wr.wr_return_amt) AS total_return_amount,
            CASE
                WHEN SUM(wr.wr_return_amt) > (SELECT AVG(wr2.wr_return_amt) FROM web_returns wr2)
                THEN 'HIGH'
                ELSE 'NORMAL'
            END AS return_category
        FROM web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
        WHERE d.d_year BETWEEN 2000 AND 2002
        GROUP BY d.d_year, r.r_reason_desc
    ),

    -- Union of the two aggregated result sets
    combined AS (
        SELECT year, reason, total_return_amount, return_category FROM catalog_returns_agg
        UNION ALL
        SELECT year, reason, total_return_amount, return_category FROM web_returns_agg
    )
SELECT
    year,
    reason,
    total_return_amount,
    return_category
FROM combined
ORDER BY year DESC, total_return_amount DESC
LIMIT 100
