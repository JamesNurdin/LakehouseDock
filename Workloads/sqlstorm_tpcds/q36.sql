WITH sales AS (
    SELECT 
        i.i_category,
        i.i_class,
        i.i_brand,
        d.d_year,
        d.d_month_seq AS month_seq,
        s.s_state AS store_state,
        SUM(ss.ss_ext_sales_price) AS sales_amount,
        SUM(ss.ss_net_profit) AS profit_amount,
        SUM(ss.ss_quantity) AS units_sold
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
    GROUP BY i.i_category, i.i_class, i.i_brand, d.d_year, d.d_month_seq, s.s_state
),
returns AS (
    SELECT 
        i.i_category,
        i.i_class,
        i.i_brand,
        d.d_year,
        d.d_month_seq AS month_seq,
        s.s_state AS store_state,
        SUM(sr.sr_return_amt) AS return_amount,
        SUM(sr.sr_return_quantity) AS return_quantity
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
    GROUP BY i.i_category, i.i_class, i.i_brand, d.d_year, d.d_month_seq, s.s_state
),
catalog AS (
    SELECT 
        i.i_category,
        i.i_class,
        i.i_brand,
        d.d_year,
        d.d_month_seq AS month_seq,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(cs.cs_quantity) AS catalog_units_sold
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
    GROUP BY i.i_category, i.i_class, i.i_brand, d.d_year, d.d_month_seq
),
catalog_returns AS (
    SELECT 
        i.i_category,
        i.i_class,
        i.i_brand,
        d.d_year,
        d.d_month_seq AS month_seq,
        SUM(cr.cr_return_amount) AS catalog_return_amount,
        SUM(cr.cr_return_quantity) AS catalog_return_quantity
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
    GROUP BY i.i_category, i.i_class, i.i_brand, d.d_year, d.d_month_seq
),
combined AS (
    SELECT 
        s.i_category,
        s.i_class,
        s.i_brand,
        s.d_year,
        s.month_seq,
        s.store_state AS region,
        s.sales_amount,
        s.profit_amount,
        s.units_sold,
        COALESCE(r.return_amount, 0) AS return_amount,
        COALESCE(r.return_quantity, 0) AS return_quantity,
        COALESCE(c.catalog_sales_amount, 0) AS catalog_sales_amount,
        COALESCE(c.catalog_profit, 0) AS catalog_profit,
        COALESCE(c.catalog_units_sold, 0) AS catalog_units_sold,
        COALESCE(cr.catalog_return_amount, 0) AS catalog_return_amount,
        COALESCE(cr.catalog_return_quantity, 0) AS catalog_return_quantity
    FROM sales s
    LEFT JOIN returns r 
        ON s.i_category = r.i_category 
        AND s.i_class = r.i_class 
        AND s.i_brand = r.i_brand 
        AND s.d_year = r.d_year 
        AND s.month_seq = r.month_seq 
        AND s.store_state = r.store_state
    LEFT JOIN catalog c 
        ON s.i_category = c.i_category 
        AND s.i_class = c.i_class 
        AND s.i_brand = c.i_brand 
        AND s.d_year = c.d_year 
        AND s.month_seq = c.month_seq
    LEFT JOIN catalog_returns cr 
        ON s.i_category = cr.i_category 
        AND s.i_class = cr.i_class 
        AND s.i_brand = cr.i_brand 
        AND s.d_year = cr.d_year 
        AND s.month_seq = cr.month_seq
)
SELECT 
    i_category,
    i_class,
    i_brand,
    d_year,
    month_seq,
    region,
    sales_amount,
    catalog_sales_amount,
    (sales_amount + catalog_sales_amount) AS total_sales_amount,
    profit_amount,
    catalog_profit,
    (profit_amount + catalog_profit) AS total_profit,
    (units_sold + catalog_units_sold) AS total_units,
    return_amount,
    catalog_return_amount,
    (return_amount + catalog_return_amount) AS total_return_amount,
    (return_quantity + catalog_return_quantity) AS total_return_quantity,
    CASE 
        WHEN (sales_amount + catalog_sales_amount) = 0 THEN 0 
        ELSE (return_amount + catalog_return_amount) / (sales_amount + catalog_sales_amount) 
    END AS return_rate,
    DENSE_RANK() OVER (ORDER BY CASE 
                                    WHEN (sales_amount + catalog_sales_amount) = 0 THEN 0 
                                    ELSE (return_amount + catalog_return_amount) / (sales_amount + catalog_sales_amount) 
                                END DESC) AS return_rate_rank,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY (profit_amount + catalog_profit) DESC) AS profit_rank_year
FROM combined
WHERE (sales_amount + catalog_sales_amount) > 0
ORDER BY d_year, month_seq, total_sales_amount DESC
LIMIT 100
