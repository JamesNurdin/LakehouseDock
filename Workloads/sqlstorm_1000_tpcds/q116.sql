WITH
catalog_sales_agg AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        i.i_brand AS brand,
        SUM(cs.cs_net_paid) AS catalog_sales,
        SUM(cs.cs_net_profit) AS catalog_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year, i.i_category, i.i_brand
),
store_sales_agg AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        i.i_brand AS brand,
        SUM(ss.ss_net_paid) AS store_sales,
        SUM(ss.ss_net_profit) AS store_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year, i.i_category, i.i_brand
),
web_sales_agg AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        i.i_brand AS brand,
        SUM(ws.ws_net_paid) AS web_sales,
        SUM(ws.ws_net_profit) AS web_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year, i.i_category, i.i_brand
),
catalog_returns_agg AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        i.i_brand AS brand,
        SUM(cr.cr_return_amount) AS catalog_return
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year, i.i_category, i.i_brand
),
store_returns_agg AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        i.i_brand AS brand,
        SUM(sr.sr_return_amt) AS store_return
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year, i.i_category, i.i_brand
),
web_returns_agg AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        i.i_brand AS brand,
        SUM(wr.wr_return_amt) AS web_return
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year, i.i_category, i.i_brand
),
combined_sales AS (
    SELECT
        COALESCE(cs.year, ss.year, ws.year) AS year,
        COALESCE(cs.category, ss.category, ws.category) AS category,
        COALESCE(cs.brand, ss.brand, ws.brand) AS brand,
        cs.catalog_sales,
        cs.catalog_profit,
        ss.store_sales,
        ss.store_profit,
        ws.web_sales,
        ws.web_profit
    FROM catalog_sales_agg cs
    FULL OUTER JOIN store_sales_agg ss
        ON cs.year = ss.year AND cs.category = ss.category AND cs.brand = ss.brand
    FULL OUTER JOIN web_sales_agg ws
        ON COALESCE(cs.year, ss.year) = ws.year
        AND COALESCE(cs.category, ss.category) = ws.category
        AND COALESCE(cs.brand, ss.brand) = ws.brand
),
combined_returns AS (
    SELECT
        COALESCE(cr.year, sr.year, wr.year) AS year,
        COALESCE(cr.category, sr.category, wr.category) AS category,
        COALESCE(cr.brand, sr.brand, wr.brand) AS brand,
        cr.catalog_return,
        sr.store_return,
        wr.web_return
    FROM catalog_returns_agg cr
    FULL OUTER JOIN store_returns_agg sr
        ON cr.year = sr.year AND cr.category = sr.category AND cr.brand = sr.brand
    FULL OUTER JOIN web_returns_agg wr
        ON COALESCE(cr.year, sr.year) = wr.year
        AND COALESCE(cr.category, sr.category) = wr.category
        AND COALESCE(cr.brand, sr.brand) = wr.brand
),
final AS (
    SELECT
        s.year,
        s.category,
        s.brand,
        COALESCE(s.catalog_sales, 0) - COALESCE(r.catalog_return, 0) AS catalog_net_sales,
        COALESCE(s.store_sales, 0) - COALESCE(r.store_return, 0) AS store_net_sales,
        COALESCE(s.web_sales, 0) - COALESCE(r.web_return, 0) AS web_net_sales,
        (COALESCE(s.catalog_sales, 0) - COALESCE(r.catalog_return, 0)) +
        (COALESCE(s.store_sales, 0) - COALESCE(r.store_return, 0)) +
        (COALESCE(s.web_sales, 0) - COALESCE(r.web_return, 0)) AS total_net_sales,
        COALESCE(s.catalog_profit, 0) + COALESCE(s.store_profit, 0) + COALESCE(s.web_profit, 0) AS total_profit
    FROM combined_sales s
    LEFT JOIN combined_returns r
        ON s.year = r.year AND s.category = r.category AND s.brand = r.brand
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY year ORDER BY total_net_sales DESC) AS sales_rank,
        SUM(total_net_sales) OVER (PARTITION BY year) AS year_total_net_sales
    FROM final
)
SELECT
    year,
    category,
    brand,
    total_net_sales,
    total_profit,
    sales_rank,
    year_total_net_sales,
    CASE WHEN sales_rank <= 5 THEN 'Top 5' ELSE 'Other' END AS rank_group
FROM ranked
WHERE total_net_sales > 0
ORDER BY year, total_net_sales DESC
LIMIT 200
