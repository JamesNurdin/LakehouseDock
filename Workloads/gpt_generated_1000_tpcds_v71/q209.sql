WITH sales_agg AS (
    SELECT
        i.i_item_id,
        d.d_year,
        SUM(cs.cs_quantity) AS total_quantity_sold,
        SUM(cs.cs_ext_sales_price) AS total_sales_amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
    GROUP BY i.i_item_id, d.d_year
),
returns_agg AS (
    SELECT
        i.i_item_id,
        d.d_year,
        SUM(wr.wr_return_quantity) AS total_quantity_returned,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
    GROUP BY i.i_item_id, d.d_year
)
SELECT
    sa.i_item_id,
    sa.d_year,
    sa.total_quantity_sold AS quantity,
    sa.total_sales_amount AS amount,
    'sale' AS txn_type,
    CASE WHEN sa.total_quantity_sold > 100 THEN 'High Volume' ELSE 'Low Volume' END AS volume_category
FROM sales_agg sa
UNION ALL
SELECT
    ra.i_item_id,
    ra.d_year,
    ra.total_quantity_returned AS quantity,
    ra.total_return_amount AS amount,
    'return' AS txn_type,
    CASE WHEN ra.total_quantity_returned > 50 THEN 'High Returns' ELSE 'Low Returns' END AS volume_category
FROM returns_agg ra
ORDER BY d_year DESC, i_item_id, txn_type
LIMIT 100
