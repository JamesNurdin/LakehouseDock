WITH
    returns_summary AS (
        SELECT
            cr_order_number,
            cr_item_sk,
            SUM(cr_return_quantity) AS total_return_qty,
            SUM(cr_return_amount) AS total_return_amount,
            COUNT(*) AS return_cnt
        FROM catalog_returns
        WHERE cr_fee > 20.00
          AND cr_returned_time_sk IN (
              SELECT t_time_sk
              FROM time_dim
              WHERE t_hour BETWEEN 8 AND 12
          )
        GROUP BY cr_order_number, cr_item_sk
    ),
    union_data AS (
        SELECT
            cc.cc_division AS division,
            i.i_category   AS category,
            SUM(cs.cs_ext_sales_price)                         AS total_sales,
            SUM(COALESCE(rs.total_return_amount, 0))           AS total_returns,
            COUNT(DISTINCT cs.cs_order_number)                AS orders,
            AVG(cs.cs_ext_sales_price)                         AS avg_sales
        FROM catalog_sales cs
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
        LEFT JOIN returns_summary rs
               ON cs.cs_order_number = rs.cr_order_number
              AND cs.cs_item_sk = rs.cr_item_sk
        WHERE cc.cc_division = 1
          AND i.i_category = 'Sports'
          AND cs.cs_ext_sales_price > 1000
          AND td.t_hour BETWEEN 9 AND 17
          AND cc.cc_rec_start_date BETWEEN DATE '2000-01-01' AND DATE '2001-12-31'
          AND cp.cp_description LIKE '%field%'
        GROUP BY cc.cc_division, i.i_category

        UNION

        SELECT
            cc.cc_division AS division,
            i.i_category   AS category,
            SUM(cs.cs_ext_sales_price)                         AS total_sales,
            SUM(COALESCE(rs.total_return_amount, 0))           AS total_returns,
            COUNT(DISTINCT cs.cs_order_number)                AS orders,
            AVG(cs.cs_ext_sales_price)                         AS avg_sales
        FROM catalog_sales cs
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
        LEFT JOIN returns_summary rs
               ON cs.cs_order_number = rs.cr_order_number
              AND cs.cs_item_sk = rs.cr_item_sk
        WHERE cc.cc_division = 2
          AND i.i_category = 'Electronics'
          AND cs.cs_ext_sales_price > 500
          AND td.t_hour BETWEEN 12 AND 20
          AND cc.cc_rec_start_date BETWEEN DATE '2002-01-01' AND DATE '2003-12-31'
          AND cp.cp_description LIKE '%service%'
        GROUP BY cc.cc_division, i.i_category
    )
SELECT
    division,
    category,
    total_sales,
    total_returns,
    orders,
    avg_sales
FROM union_data
ORDER BY total_sales DESC
OFFSET 0 LIMIT 100
