WITH
    avg_sales AS (
        SELECT AVG(ss_ext_sales_price) AS avg_sales
        FROM store_sales
    ),
    avg_loss AS (
        SELECT AVG(sr_net_loss) AS avg_loss
        FROM store_returns
    ),
    sales_stats AS (
        SELECT s.s_store_id,
               SUM(ss.ss_ext_sales_price) AS total_sales,
               CASE WHEN SUM(ss.ss_ext_sales_price) > (SELECT avg_sales FROM avg_sales)
                    THEN 'HIGH' ELSE 'LOW' END AS sales_category
        FROM store s
        JOIN store_sales ss ON ss.ss_store_sk = s.s_store_sk
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2002
        GROUP BY s.s_store_id
        HAVING SUM(ss.ss_ext_sales_price) > (SELECT avg_sales FROM avg_sales)
    ),
    returns_stats AS (
        SELECT s.s_store_id,
               SUM(sr.sr_net_loss) AS total_loss,
               CASE WHEN SUM(sr.sr_net_loss) > (SELECT avg_loss FROM avg_loss)
                    THEN 'HIGH' ELSE 'LOW' END AS loss_category
        FROM store s
        JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2002
        GROUP BY s.s_store_id
        HAVING SUM(sr.sr_net_loss) > (SELECT avg_loss FROM avg_loss)
    ),
    -- expand a derived array per store to satisfy UNNEST requirement
    store_years AS (
        SELECT s.s_store_id,
               ARRAY[2001, 2002, 2003] AS years
        FROM store s
    ),
    expanded_years AS (
        SELECT sy.s_store_id,
               y AS yr
        FROM store_years sy
        CROSS JOIN UNNEST(sy.years) AS t(y)
    ),
    intersected_ids AS (
        SELECT s_store_id FROM sales_stats
        INTERSECT
        SELECT s_store_id FROM returns_stats
    )
SELECT i.s_store_id,
       ss.sales_category,
       rs.loss_category,
       COUNT(*) OVER (PARTITION BY ss.sales_category) AS stores_in_category
FROM intersected_ids i
JOIN sales_stats ss ON ss.s_store_id = i.s_store_id
JOIN returns_stats rs ON rs.s_store_id = i.s_store_id
JOIN expanded_years ey ON ey.s_store_id = i.s_store_id AND ey.yr = 2002
ORDER BY i.s_store_id
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
