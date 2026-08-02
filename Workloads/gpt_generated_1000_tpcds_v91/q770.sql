/* Goal: Summarize combined catalog and web sales by year, category and brand, compute total sales, rank categories per year, and isolate orders that exist in both catalog and web channels with detailed filters. */
WITH intersect_orders AS (
    SELECT cs.cs_order_number AS order_number
    FROM catalog_sales cs
    JOIN date_dim d1 ON cs.cs_sold_date_sk = d1.d_date_sk
    WHERE d1.d_year = 2000
      AND cs.cs_quantity > 1
      AND cs.cs_ext_sales_price > 0
      AND cs.cs_ship_mode_sk = (
          SELECT sm_ship_mode_sk
          FROM ship_mode
          WHERE sm_code = 'AIR'
      )
    INTERSECT
    SELECT ws.ws_order_number AS order_number
    FROM web_sales ws
    JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2000
      AND ws.ws_quantity > 1
      AND ws.ws_ext_sales_price > 0
      AND ws.ws_ship_mode_sk = (
          SELECT sm_ship_mode_sk
          FROM ship_mode
          WHERE sm_code = 'AIR'
      )
),
aggregated_sales AS (
    SELECT
        d.d_year,
        i.i_category,
        i.i_brand,
        SUM(cs.cs_ext_sales_price) AS catalog_sales,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        SUM(cs.cs_ext_sales_price + ws.ws_ext_sales_price) AS total_sales
    FROM intersect_orders io
    JOIN catalog_sales cs ON cs.cs_order_number = io.order_number
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN web_sales ws ON ws.ws_order_number = io.order_number
        AND ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = i.i_item_sk
        AND wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE
        d.d_year = 2000
        AND cc.cc_state = 'CA'
        AND i.i_brand IN ('Brand#12', 'Brand#23')
        AND sm.sm_code = 'AIR'
        AND t.t_hour BETWEEN 9 AND 18
        AND wr.wr_return_quantity > 0
        AND i.i_size = 'L'
        AND EXISTS (
            SELECT 1
            FROM catalog_returns cr
            JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
            WHERE cr.cr_order_number = cs.cs_order_number
              AND cr.cr_return_quantity > 0
              AND r.r_reason_desc LIKE '%damaged%'
        )
    GROUP BY GROUPING SETS (
        (d.d_year, i.i_category, i.i_brand),
        (d.d_year, i.i_category),
        (d.d_year),
        ()
    )
)
SELECT
    d_year,
    i_category,
    i_brand,
    catalog_sales,
    web_sales,
    total_sales,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY (catalog_sales + web_sales) DESC) AS sales_rank
FROM aggregated_sales
ORDER BY d_year DESC, total_sales DESC
LIMIT 100
