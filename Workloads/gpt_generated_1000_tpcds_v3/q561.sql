WITH returns_agg AS (
    SELECT
        cp.cp_department AS department,
        d_wr.d_year AS return_year,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        AVG(wr.wr_return_tax) AS avg_return_tax
    FROM web_returns wr
    JOIN date_dim d_wr
        ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d_wr.d_date_sk
    WHERE
        wr.wr_return_amt_inc_tax > 100.0
        AND wr.wr_return_quantity BETWEEN 1 AND 5
        AND cp.cp_department IN ('Shoes', 'Electronics', 'Clothing')
        AND cp.cp_type = 'Catalog'
        AND d_wr.d_year BETWEEN 2000 AND 2003
        AND EXISTS (
            SELECT 1
            FROM promotion p
            WHERE p.p_start_date_sk = d_wr.d_date_sk
              AND p.p_channel_event = 'N'
              AND p.p_discount_active = 'Y'
              AND p.p_purpose = 'Clearance'
        )
    GROUP BY cp.cp_department, d_wr.d_year
)
SELECT
    department,
    return_year,
    total_return_amt,
    total_return_qty,
    avg_return_tax,
    RANK() OVER (ORDER BY total_return_amt DESC) AS total_return_amt_rank,
    SUM(total_return_amt) OVER (
        PARTITION BY department
        ORDER BY return_year
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_return_amt_by_year
FROM returns_agg
ORDER BY total_return_amt DESC
LIMIT 100
