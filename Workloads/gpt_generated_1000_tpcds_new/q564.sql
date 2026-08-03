WITH key_set1 AS (
    SELECT cs_order_number
    FROM catalog_sales
    WHERE cs_sales_price > 100
),
key_set2 AS (
    SELECT cs_order_number
    FROM catalog_sales
    WHERE cs_quantity > 5
),
common_orders AS (
    SELECT cs_order_number FROM key_set1
    INTERSECT
    SELECT cs_order_number FROM key_set2
),
union_data AS (
    SELECT
        cp.cp_catalog_page_number,
        cp.cp_department,
        cs.cs_sold_date_sk,
        cs.cs_sales_price,
        cs.cs_quantity,
        sr.sr_return_amt AS return_amt,
        td.t_second,
        cs.cs_order_number
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN store_returns sr ON sr.sr_return_time_sk = td.t_time_sk
    WHERE cp.cp_catalog_page_number IN (1, 10, 17)
      AND cs.cs_sales_price > 50
      AND td.t_second = 11
      AND cs.cs_order_number IN (SELECT cs_order_number FROM common_orders)
      AND EXISTS (
          SELECT 1 FROM catalog_page cp2
          WHERE cp2.cp_department = cp.cp_department
            AND cp2.cp_description LIKE '%intensive%'
      )
    UNION
    SELECT
        cp.cp_catalog_page_number,
        cp.cp_department,
        cs.cs_sold_date_sk,
        cs.cs_sales_price,
        cs.cs_quantity,
        wr.wr_return_amt AS return_amt,
        td.t_second,
        cs.cs_order_number
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN web_returns wr ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE cp.cp_catalog_page_number IN (1, 10, 17)
      AND cs.cs_sales_price > 50
      AND td.t_second = 11
      AND cs.cs_order_number IN (SELECT cs_order_number FROM common_orders)
      AND EXISTS (
          SELECT 1 FROM catalog_page cp2
          WHERE cp2.cp_department = cp.cp_department
            AND cp2.cp_description LIKE '%intensive%'
      )
),
unnested AS (
    SELECT
        ud.cp_catalog_page_number,
        ud.cp_department,
        ud.cs_sold_date_sk,
        ud.cs_sales_price,
        ud.cs_quantity,
        ud.return_amt,
        ud.t_second,
        ud.cs_order_number,
        unnested_val AS qty_or_return
    FROM union_data ud
    CROSS JOIN UNNEST(ARRAY[ud.cs_quantity, CAST(ud.return_amt AS integer)]) AS t(unnested_val)
),
agg AS (
    SELECT
        cp_catalog_page_number,
        cp_department,
        COUNT(DISTINCT cs_order_number) AS order_cnt,
        SUM(cs_sales_price) AS total_sales,
        AVG(cs_sales_price) AS avg_sales,
        MIN(cs_sales_price) AS min_sales,
        MAX(cs_sales_price) AS max_sales,
        SUM(qty_or_return) AS sum_qty_or_return
    FROM unnested
    GROUP BY cp_catalog_page_number, cp_department
),
final AS (
    SELECT
        a.*, 
        LAG(total_sales) OVER (PARTITION BY cp_department ORDER BY cp_catalog_page_number) AS lag_total_sales,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rn,
        (SELECT MAX(cs_sales_price) FROM catalog_sales) AS overall_max_price
    FROM agg a
)
SELECT *
FROM final
ORDER BY total_sales DESC
LIMIT 100
