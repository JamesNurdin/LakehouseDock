WITH
catalog_sales_agg AS (
    SELECT d.d_year AS year,
           d.d_month_seq AS month_seq,
           i.i_category AS category,
           i.i_class AS class,
           i.i_brand AS brand,
           SUM(cs.cs_ext_sales_price) AS total_sales,
           SUM(cs.cs_ext_discount_amt) AS total_discount,
           SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_class, i.i_brand
),
catalog_returns_agg AS (
    SELECT d.d_year AS year,
           d.d_month_seq AS month_seq,
           i.i_category AS category,
           i.i_class AS class,
           i.i_brand AS brand,
           SUM(cr.cr_return_amount) AS total_returns
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_class, i.i_brand
),
store_sales_agg AS (
    SELECT d.d_year AS year,
           d.d_month_seq AS month_seq,
           i.i_category AS category,
           i.i_class AS class,
           i.i_brand AS brand,
           SUM(ss.ss_ext_sales_price) AS total_sales,
           SUM(ss.ss_ext_discount_amt) AS total_discount,
           SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_class, i.i_brand
),
store_returns_agg AS (
    SELECT d.d_year AS year,
           d.d_month_seq AS month_seq,
           i.i_category AS category,
           i.i_class AS class,
           i.i_brand AS brand,
           SUM(sr.sr_return_amt) AS total_returns
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_class, i.i_brand
),
web_sales_agg AS (
    SELECT d.d_year AS year,
           d.d_month_seq AS month_seq,
           i.i_category AS category,
           i.i_class AS class,
           i.i_brand AS brand,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           SUM(ws.ws_ext_discount_amt) AS total_discount,
           SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_class, i.i_brand
),
web_returns_agg AS (
    SELECT d.d_year AS year,
           d.d_month_seq AS month_seq,
           i.i_category AS category,
           i.i_class AS class,
           i.i_brand AS brand,
           SUM(wr.wr_return_amt) AS total_returns
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_class, i.i_brand
)
SELECT
    year,
    month_seq,
    category,
    class,
    brand,
    total_sales,
    total_discount,
    total_profit,
    net_sales,
    discount_rate,
    RANK() OVER (PARTITION BY year, month_seq ORDER BY total_profit DESC) AS profit_rank
FROM (
    SELECT
        year,
        month_seq,
        category,
        class,
        brand,
        SUM(total_sales) AS total_sales,
        SUM(total_discount) AS total_discount,
        SUM(total_profit) AS total_profit,
        SUM(total_sales) - SUM(COALESCE(total_returns, 0)) AS net_sales,
        CASE WHEN SUM(total_sales) = 0 THEN 0 ELSE SUM(total_discount) / SUM(total_sales) END AS discount_rate
    FROM (
        SELECT cs.year,
               cs.month_seq,
               cs.category,
               cs.class,
               cs.brand,
               cs.total_sales,
               cs.total_discount,
               cs.total_profit,
               cr.total_returns
        FROM catalog_sales_agg cs
        LEFT JOIN catalog_returns_agg cr
            ON cs.year = cr.year
            AND cs.month_seq = cr.month_seq
            AND cs.category = cr.category
            AND cs.class = cr.class
            AND cs.brand = cr.brand

        UNION ALL

        SELECT ss.year,
               ss.month_seq,
               ss.category,
               ss.class,
               ss.brand,
               ss.total_sales,
               ss.total_discount,
               ss.total_profit,
               sr.total_returns
        FROM store_sales_agg ss
        LEFT JOIN store_returns_agg sr
            ON ss.year = sr.year
            AND ss.month_seq = sr.month_seq
            AND ss.category = sr.category
            AND ss.class = sr.class
            AND ss.brand = sr.brand

        UNION ALL

        SELECT ws.year,
               ws.month_seq,
               ws.category,
               ws.class,
               ws.brand,
               ws.total_sales,
               ws.total_discount,
               ws.total_profit,
               wr.total_returns
        FROM web_sales_agg ws
        LEFT JOIN web_returns_agg wr
            ON ws.year = wr.year
            AND ws.month_seq = wr.month_seq
            AND ws.category = wr.category
            AND ws.class = wr.class
            AND ws.brand = wr.brand
    ) t
    GROUP BY year, month_seq, category, class, brand
) s
ORDER BY year, month_seq, total_sales DESC
