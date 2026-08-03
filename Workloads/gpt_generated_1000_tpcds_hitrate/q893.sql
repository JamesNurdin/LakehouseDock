WITH base AS (
    SELECT
        d1.d_year AS d_year,
        s.s_store_name AS s_store_name,
        i.i_category AS i_category,
        i.i_current_price AS i_current_price,
        cr.cr_return_amount AS cr_return_amount,
        sr.sr_return_amt AS sr_return_amt,
        ws.ws_net_paid AS ws_net_paid,
        ws.ws_order_number AS ws_order_number,
        ARRAY[i.i_brand, i.i_category] AS brand_category_arr,
        d1.d_date_sk AS cr_date_sk,
        d2.d_date_sk AS sr_date_sk,
        d3.d_date_sk AS wr_date_sk
    FROM catalog_page cp
    JOIN catalog_returns cr ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d1 ON cr.cr_returned_date_sk = d1.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d2 ON sr.sr_returned_date_sk = d2.d_date_sk
    JOIN time_dim t2 ON sr.sr_return_time_sk = t2.t_time_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_order_number = ws.ws_order_number
    JOIN date_dim d3 ON wr.wr_returned_date_sk = d3.d_date_sk
    JOIN time_dim t3 ON wr.wr_returned_time_sk = t3.t_time_sk
    WHERE d1.d_year = 2001
      AND t.t_shift = 'first'
      AND s.s_state = 'CA'
      AND i.i_brand = 'BrandX'
      AND r.r_reason_desc LIKE '%defect%'
      AND hd.hd_buy_potential = 'High'
)
,
unioned AS (
    SELECT
        d_year,
        s_store_name,
        i_category,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(sr_return_amt) AS total_store_return,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS distinct_orders,
        CASE WHEN i_current_price > 100 THEN 'Expensive' ELSE 'Standard' END AS price_category,
        (SELECT MAX(cr_return_amount) FROM catalog_returns cr2 WHERE cr2.cr_returned_date_sk = cr_date_sk) AS extreme_return_amount,
        COUNT(DISTINCT attr) AS distinct_brand_category
    FROM base
    LEFT JOIN UNNEST(brand_category_arr) AS u(attr) ON TRUE
    GROUP BY d_year, s_store_name, i_category, i_current_price, cr_date_sk
    HAVING SUM(cr_return_amount) > 1000
    
    UNION DISTINCT
    
    SELECT
        d_year,
        s_store_name,
        i_category,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(sr_return_amt) AS total_store_return,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS distinct_orders,
        CASE WHEN i_current_price > 200 THEN 'Very Expensive' ELSE 'Affordable' END AS price_category,
        (SELECT MIN(cr_return_amount) FROM catalog_returns cr2 WHERE cr2.cr_returned_date_sk = cr_date_sk) AS extreme_return_amount,
        COUNT(DISTINCT attr) AS distinct_brand_category
    FROM base
    LEFT JOIN UNNEST(brand_category_arr) AS u(attr) ON TRUE
    GROUP BY d_year, s_store_name, i_category, i_current_price, cr_date_sk
    HAVING SUM(sr_return_amt) > 500
)
SELECT *
FROM unioned
ORDER BY total_sales DESC
LIMIT 100
