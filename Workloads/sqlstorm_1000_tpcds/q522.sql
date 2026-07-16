WITH
    sales_agg AS (
        SELECT
            cs.cs_sold_date_sk AS sold_date_sk,
            d.d_year,
            cs.cs_item_sk AS item_sk,
            i.i_category,
            i.i_color,
            SUM(cs.cs_net_paid) AS total_net_paid,
            SUM(cs.cs_net_profit) AS total_net_profit,
            COUNT(*) AS sales_cnt
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        WHERE cs.cs_net_paid IS NOT NULL
        GROUP BY cs.cs_sold_date_sk, d.d_year, cs.cs_item_sk, i.i_category, i.i_color
    ),
    top_sales AS (
        SELECT
            *,
            ROW_NUMBER() OVER (PARTITION BY sold_date_sk ORDER BY total_net_paid DESC) AS rn
        FROM sales_agg
    ),
    top_sales_filtered AS (
        SELECT *
        FROM top_sales
        WHERE rn <= 3
    ),
    returns_agg AS (
        SELECT
            cr.cr_item_sk AS item_sk,
            d_ret.d_year AS ret_year,
            SUM(cr.cr_return_amount) AS total_return_amount,
            COUNT(DISTINCT cr.cr_order_number) AS distinct_orders_returned
        FROM catalog_returns cr
        JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
        WHERE cr.cr_return_amount > 0
        GROUP BY cr.cr_item_sk, d_ret.d_year
    ),
    combined_sales AS (
        SELECT
            ts.sold_date_sk,
            ts.d_year,
            ts.item_sk,
            ts.i_category,
            COALESCE(ts.i_color, 'UNKNOWN') AS item_color,
            ts.total_net_paid,
            ts.total_net_profit,
            ts.sales_cnt,
            COALESCE(ra.total_return_amount, 0) AS total_return_amount,
            COALESCE(ra.distinct_orders_returned, 0) AS distinct_orders_returned,
            CASE 
                WHEN ts.total_net_paid = 0 THEN NULL
                ELSE ra.total_return_amount / ts.total_net_paid
            END AS return_to_sales_ratio,
            CONCAT(ts.i_category, '-', COALESCE(ts.i_color, 'UNKNOWN')) AS cat_color_key,
            (SELECT AVG(cs2.cs_net_paid)
             FROM catalog_sales cs2
             JOIN item i2 ON cs2.cs_item_sk = i2.i_item_sk
             WHERE i2.i_category = ts.i_category
               AND cs2.cs_sold_date_sk = ts.sold_date_sk) AS avg_category_sales_same_day,
            CASE WHEN ts.total_net_profit < 0 THEN 'LOSS' ELSE 'PROFIT' END AS profit_indicator
        FROM top_sales_filtered ts
        LEFT JOIN returns_agg ra
            ON ts.item_sk = ra.item_sk
            AND ts.d_year = ra.ret_year
    ),
    store_sales_agg AS (
        SELECT
            ss.ss_sold_date_sk AS sold_date_sk,
            d_s.d_year,
            ss.ss_item_sk AS item_sk,
            i_s.i_category,
            SUM(ss.ss_net_paid) AS total_store_net_paid,
            SUM(ss.ss_net_profit) AS total_store_net_profit,
            COUNT(*) AS store_sales_cnt
        FROM store_sales ss
        JOIN date_dim d_s ON ss.ss_sold_date_sk = d_s.d_date_sk
        JOIN item i_s ON ss.ss_item_sk = i_s.i_item_sk
        GROUP BY ss.ss_sold_date_sk, d_s.d_year, ss.ss_item_sk, i_s.i_category
    ),
    top_store_sales AS (
        SELECT
            *,
            ROW_NUMBER() OVER (PARTITION BY sold_date_sk ORDER BY total_store_net_paid DESC) AS rn_store
        FROM store_sales_agg
    ),
    top_store_sales_filtered AS (
        SELECT *
        FROM top_store_sales
        WHERE rn_store <= 3
    ),
    union_all_sales AS (
        SELECT
            cs.sold_date_sk,
            cs.d_year,
            cs.item_sk,
            cs.i_category,
            cs.item_color,
            cs.total_net_paid,
            cs.total_net_profit,
            cs.sales_cnt,
            cs.total_return_amount,
            cs.distinct_orders_returned,
            cs.return_to_sales_ratio,
            cs.cat_color_key,
            cs.avg_category_sales_same_day,
            cs.profit_indicator,
            'catalog' AS source
        FROM combined_sales cs
        UNION ALL
        SELECT
            ss.sold_date_sk,
            ss.d_year,
            ss.item_sk,
            ss.i_category,
            NULL AS item_color,
            ss.total_store_net_paid AS total_net_paid,
            ss.total_store_net_profit AS total_net_profit,
            ss.store_sales_cnt AS sales_cnt,
            0.0 AS total_return_amount,
            0 AS distinct_orders_returned,
            NULL AS return_to_sales_ratio,
            CONCAT(ss.i_category, '-STORE') AS cat_color_key,
            NULL AS avg_category_sales_same_day,
            CASE WHEN ss.total_store_net_profit < 0 THEN 'LOSS' ELSE 'PROFIT' END AS profit_indicator,
            'store' AS source
        FROM top_store_sales_filtered ss
    )
SELECT *
FROM union_all_sales
WHERE (source = 'catalog' AND return_to_sales_ratio IS NOT NULL AND return_to_sales_ratio > 0.1)
   OR (source = 'store' AND total_net_profit > 5000)
ORDER BY d_year DESC, total_net_paid DESC
LIMIT 200
