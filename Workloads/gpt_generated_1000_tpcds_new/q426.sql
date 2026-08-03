WITH
    -- Aggregate store return losses per store for the target year
    returns_agg AS (
        SELECT
            s.s_store_name AS location_name,
            CASE WHEN SUM(sr.sr_net_loss) > 5000 THEN 'HIGH' ELSE 'LOW' END AS profit_flag,
            SUM(sr.sr_net_loss) AS amount,
            d.d_year AS year
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        WHERE d.d_year = 2001
        GROUP BY s.s_store_name, d.d_year
    ),
    -- Small dimension: months in the target year
    cross_month AS (
        SELECT d_month_seq
        FROM date_dim
        WHERE d_year = 2001
        GROUP BY d_month_seq
    ),
    -- Total sales amount for the target year (single scalar value)
    sales_total AS (
        SELECT SUM(cs.cs_ext_sales_price) AS total_sales
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
    ),
    -- Expand warehouse IDs into characters and count them
    warehouse_char_counts AS (
        SELECT
            w.w_warehouse_sk,
            COUNT(*) AS char_cnt
        FROM warehouse w
        CROSS JOIN UNNEST(split(w.w_warehouse_id, '')) AS t(ch)
        GROUP BY w.w_warehouse_sk
    ),
    char_counts AS (
        SELECT SUM(char_cnt) AS total_chars
        FROM warehouse_char_counts
    ),
    -- Rows representing monthly sales (cartesian product with the scalar total_sales)
    monthly_sales AS (
        SELECT
            CAST(m.d_month_seq AS varchar) AS location_name,
            'MONTH' AS profit_flag,
            CAST(s.total_sales AS decimal(15,2)) AS amount,
            2001 AS year
        FROM cross_month m
        CROSS JOIN sales_total s
    ),
    -- Row representing total characters in all warehouse IDs
    warehouse_chars_row AS (
        SELECT
            'WAREHOUSE_CHARS' AS location_name,
            CASE WHEN total_chars > 100 THEN 'HIGH' ELSE 'LOW' END AS profit_flag,
            CAST(total_chars AS decimal(15,2)) AS amount,
            2001 AS year
        FROM char_counts
    )
SELECT location_name,
       profit_flag,
       amount,
       year
FROM returns_agg
WHERE year = 2001

UNION ALL

SELECT location_name,
       profit_flag,
       amount,
       year
FROM monthly_sales

UNION ALL

SELECT location_name,
       profit_flag,
       amount,
       year
FROM warehouse_chars_row

ORDER BY amount DESC, location_name
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
