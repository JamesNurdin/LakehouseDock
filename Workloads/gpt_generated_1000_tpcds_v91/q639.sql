WITH base AS (
    SELECT 
        d.d_year,
        s.s_state,
        hd.hd_buy_potential,
        cp.cp_type,
        w.w_city,
        wp.wp_autogen_flag,
        ss.ss_ext_sales_price AS sales_price,
        cr.cr_return_amount AS return_amount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND hd.hd_buy_potential = '0-500'
      AND s.s_state = 'CA'
      AND wp.wp_autogen_flag = 'Y'
      AND cp.cp_type = 'TEXT'
      AND w.w_city = 'San Francisco'
      AND d.d_same_day_lq BETWEEN 2414936 AND 2414941
),
agg1 AS (
    SELECT 
        d_year,
        s_state,
        hd_buy_potential,
        cp_type,
        w_city,
        wp_autogen_flag,
        SUM(sales_price) AS total_sales,
        SUM(return_amount) AS total_returns
    FROM base
    GROUP BY d_year, s_state, hd_buy_potential, cp_type, w_city, wp_autogen_flag
    HAVING SUM(sales_price) > 10000
),
agg2 AS (
    SELECT 
        d_year,
        s_state,
        hd_buy_potential,
        cp_type,
        w_city,
        wp_autogen_flag,
        SUM(sales_price) * 0.9 AS total_sales,
        SUM(return_amount) * 1.1 AS total_returns
    FROM base
    GROUP BY d_year, s_state, hd_buy_potential, cp_type, w_city, wp_autogen_flag
    HAVING SUM(return_amount) > 0
),
combined AS (
    SELECT * FROM agg1
    UNION ALL
    SELECT * FROM agg2
),
exclude AS (
    SELECT 
        d_year,
        s_state,
        hd_buy_potential,
        cp_type,
        w_city,
        wp_autogen_flag,
        total_sales,
        total_returns
    FROM combined
    WHERE total_returns > total_sales
),
final_set AS (
    SELECT 
        d_year,
        s_state,
        hd_buy_potential,
        cp_type,
        w_city,
        wp_autogen_flag,
        total_sales,
        total_returns
    FROM combined
    EXCEPT
    SELECT 
        d_year,
        s_state,
        hd_buy_potential,
        cp_type,
        w_city,
        wp_autogen_flag,
        total_sales,
        total_returns
    FROM exclude
)
SELECT 
    d_year,
    s_state,
    hd_buy_potential,
    cp_type,
    w_city,
    wp_autogen_flag,
    total_sales,
    total_returns,
    (total_sales - total_returns) AS net_revenue,
    CASE 
        WHEN total_returns > 0 THEN ROUND(total_returns / total_sales * 100, 2)
        ELSE 0
    END AS return_rate_percent,
    DENSE_RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank,
    SUM(total_sales) OVER (PARTITION BY d_year ORDER BY s_state ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_sales
FROM final_set
ORDER BY d_year DESC, total_sales DESC
LIMIT 100
