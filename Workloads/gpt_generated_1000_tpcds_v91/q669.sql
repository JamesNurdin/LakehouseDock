WITH ss_store_full AS (
    SELECT 
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_sales_price,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_paid,
        s.s_store_id,
        s.s_state,
        s.s_country,
        s.s_gmt_offset,
        s.s_tax_percentage,
        s.s_closed_date_sk
    FROM store_sales ss
    FULL OUTER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
),
joined_data AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        ss_full.s_state,
        ss_full.ss_ext_sales_price,
        ws.ws_ext_sales_price,
        cr.cr_return_amount,
        i.inv_quantity_on_hand,
        ss_full.ss_sales_price AS ss_sales_price,
        ws.ws_sales_price AS ws_sales_price
    FROM ss_store_full ss_full
    LEFT JOIN date_dim d
        ON ss_full.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE 
        d.d_year = 2000
        AND ss_full.ss_sales_price > 50
        AND ws.ws_sales_price > 50
),
agg_data AS (
    SELECT 
        d_year,
        s_state,
        SUM(COALESCE(ss_ext_sales_price, 0)) AS total_store_sales,
        SUM(COALESCE(ws_ext_sales_price, 0)) AS total_web_sales,
        SUM(COALESCE(cr_return_amount, 0)) AS total_returns,
        SUM(COALESCE(inv_quantity_on_hand, 0)) AS total_inventory
    FROM joined_data
    GROUP BY ROLLUP (d_year, s_state)
)
SELECT 
    d_year,
    s_state,
    total_store_sales,
    total_web_sales,
    total_returns,
    total_inventory,
    CASE 
        WHEN total_store_sales > 100000 THEN 'High'
        WHEN total_store_sales > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_store_sales DESC) AS sales_rank
FROM agg_data
ORDER BY total_store_sales DESC
LIMIT 100
