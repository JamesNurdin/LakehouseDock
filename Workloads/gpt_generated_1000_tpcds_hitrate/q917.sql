WITH store_dates AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_month_seq
    FROM store s
    FULL OUTER JOIN date_dim d
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2001 OR s.s_store_sk IS NOT NULL
),
union_returns AS (
    SELECT
        i.i_category,
        SUM(cr.cr_return_quantity) AS total_qty,
        SUM(cr.cr_return_amount) AS total_amount,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(cr.cr_return_amount) DESC) AS rnk
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND cr.cr_return_amount > (
          SELECT AVG(cr2.cr_return_amount)
          FROM catalog_returns cr2
          WHERE cr2.cr_returned_date_sk = 2000
      )
    GROUP BY i.i_category
    HAVING SUM(cr.cr_return_quantity) > 10

    UNION ALL

    SELECT
        i.i_category,
        SUM(cr.cr_return_quantity) AS total_qty,
        SUM(cr.cr_return_amount) AS total_amount,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(cr.cr_return_amount) DESC) AS rnk
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1 FROM store_dates sd WHERE sd.d_year = d.d_year
      )
    GROUP BY i.i_category
    HAVING SUM(cr.cr_return_quantity) > 10
)
SELECT
    i_category,
    total_qty,
    total_amount
FROM union_returns
WHERE rnk <= 5
ORDER BY i_category, total_amount DESC
LIMIT 100
