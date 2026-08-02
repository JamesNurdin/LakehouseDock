WITH sales_aggregated AS (
    SELECT
        s.s_store_id,
        i.i_item_sk,
        i.i_product_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(*) AS units_sold,
        SUBSTR(i.i_product_name, 1, 5) AS product_name_prefix,
        REGEXP_EXTRACT(i.i_product_name, '(.*)Premium', 1) AS premium_part
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND i.i_product_name LIKE '%Deluxe%'
      AND REGEXP_LIKE(i.i_product_name, '.*Premium.*')
    GROUP BY
        s.s_store_id,
        i.i_item_sk,
        i.i_product_name,
        SUBSTR(i.i_product_name, 1, 5),
        REGEXP_EXTRACT(i.i_product_name, '(.*)Premium', 1)
    HAVING SUM(ss.ss_ext_sales_price) > 500
),

sales_ranked AS (
    SELECT
        a.*,
        ROW_NUMBER() OVER (PARTITION BY a.s_store_id ORDER BY a.total_sales DESC) AS sales_rank
    FROM sales_aggregated a
),

returns_items AS (
    SELECT DISTINCT
        i.i_item_sk
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND r.r_reason_desc LIKE '%Defect%'
      AND REGEXP_LIKE(i.i_product_name, '^.*Basic$')
)

SELECT *
FROM (
    SELECT
        s.s_store_id,
        s.sales_rank,
        s.i_item_sk,
        s.i_product_name,
        s.total_sales,
        s.units_sold,
        s.product_name_prefix,
        s.premium_part
    FROM sales_ranked s
    EXCEPT
    SELECT
        s.s_store_id,
        s.sales_rank,
        s.i_item_sk,
        s.i_product_name,
        s.total_sales,
        s.units_sold,
        s.product_name_prefix,
        s.premium_part
    FROM sales_ranked s
    JOIN returns_items r ON s.i_item_sk = r.i_item_sk
) final_set
ORDER BY total_sales DESC
LIMIT 100
