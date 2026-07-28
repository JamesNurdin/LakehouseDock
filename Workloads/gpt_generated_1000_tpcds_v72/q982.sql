WITH catalog_sales_agg AS (
    SELECT
        d.d_year,
        i.i_item_id,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND NOT EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_item_sk = i.i_item_sk
            AND p.p_start_date_sk = cs.cs_sold_date_sk
      )
    GROUP BY d.d_year, i.i_item_id
),
store_returns_agg AS (
    SELECT
        d.d_year,
        i.i_item_id,
        SUM(sr.sr_return_amt) AS total_sales,
        SUM(sr.sr_return_quantity) AS total_quantity
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
    GROUP BY d.d_year, i.i_item_id
)
SELECT
    csa.d_year,
    csa.i_item_id,
    csa.total_sales,
    csa.total_quantity
FROM catalog_sales_agg csa
UNION ALL
SELECT
    sra.d_year,
    sra.i_item_id,
    sra.total_sales,
    sra.total_quantity
FROM store_returns_agg sra
ORDER BY d_year DESC, total_sales DESC
LIMIT 100
