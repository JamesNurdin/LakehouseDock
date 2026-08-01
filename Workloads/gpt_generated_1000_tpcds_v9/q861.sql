/* Goal: Combine sales and return metrics per brand and category for the year 2000, filter on product and store attributes, exclude brands that have any web returns, rank brands by sales, compute the average sales across brands, and return the top 100 rows. */
WITH
sales_agg AS (
    SELECT
        s.s_store_id AS store_id,
        i.i_brand AS brand,
        i.i_category AS category,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        0.0 AS total_return,
        0.0 AS total_net_loss
    FROM store_sales ss
    JOIN date_dim ds ON ss.ss_sold_date_sk = ds.d_date_sk                -- store_sales → date_dim
    JOIN item i ON ss.ss_item_sk = i.i_item_sk                           -- store_sales → item
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk    -- store_sales → household_demographics
    JOIN store s ON ss.ss_store_sk = s.s_store_sk                       -- store_sales → store
    JOIN date_dim dc ON s.s_closed_date_sk = dc.d_date_sk               -- store → date_dim (closed date)
    JOIN web_site ws ON ws.web_open_date_sk = ds.d_date_sk               -- store_sales date → web_site (open date)
    WHERE ds.d_year = 2000
      AND i.i_manufact_id IN (86, 214, 260)
      AND i.i_container = 'Unknown'
      AND hd.hd_buy_potential = '1001-5000'
      AND s.s_geography_class <> 'Unknown'
      AND s.s_floor_space > 2000
    GROUP BY s.s_store_id, i.i_brand, i.i_category
),
catalog_return_agg AS (
    SELECT
        NULL AS store_id,
        i2.i_brand AS brand,
        i2.i_category AS category,
        0.0 AS total_sales,
        SUM(cr.cr_return_amount) AS total_return,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN date_dim d2 ON cr.cr_returned_date_sk = d2.d_date_sk               -- catalog_returns → date_dim
    JOIN item i2 ON cr.cr_item_sk = i2.i_item_sk                              -- catalog_returns → item
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk    -- catalog_returns → catalog_page
    JOIN date_dim dcp_start ON cp.cp_start_date_sk = dcp_start.d_date_sk    -- catalog_page → date_dim (start)
    JOIN date_dim dcp_end   ON cp.cp_end_date_sk   = dcp_end.d_date_sk      -- catalog_page → date_dim (end)
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk                -- catalog_returns → warehouse
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk                         -- catalog_returns → reason
    JOIN web_site ws2 ON ws2.web_open_date_sk = d2.d_date_sk                 -- catalog_returns date → web_site (open)
    WHERE d2.d_year = 2000
      AND i2.i_manufact_id = 214
      AND r.r_reason_desc LIKE '%defective%'
    GROUP BY i2.i_brand, i2.i_category
),
web_return_agg AS (
    SELECT
        NULL AS store_id,
        i3.i_brand AS brand,
        i3.i_category AS category,
        0.0 AS total_sales,
        SUM(wr.wr_return_amt) AS total_return,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    JOIN date_dim d3 ON wr.wr_returned_date_sk = d3.d_date_sk               -- web_returns → date_dim
    JOIN item i3 ON wr.wr_item_sk = i3.i_item_sk                              -- web_returns → item
    JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk                       -- web_returns → reason
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk               -- web_returns → web_page
    JOIN web_site ws3 ON ws3.web_open_date_sk = d3.d_date_sk                 -- web_returns date → web_site (open)
    WHERE d3.d_year = 2000
      AND i3.i_manufact_id = 86
      AND wp.wp_type = 'Content'
    GROUP BY i3.i_brand, i3.i_category
),
union_raw AS (
    SELECT * FROM sales_agg
    UNION
    SELECT * FROM catalog_return_agg
    UNION
    SELECT * FROM web_return_agg
),
agg_grouped AS (
    SELECT
        brand,
        category,
        SUM(total_sales) AS sum_sales,
        SUM(total_return) AS sum_return,
        SUM(total_net_loss) AS sum_net_loss,
        COUNT(*) AS row_cnt
    FROM union_raw
    GROUP BY GROUPING SETS (
        (brand, category),
        (brand),
        ()
    )
),
filtered_agg AS (
    SELECT *
    FROM agg_grouped a
    WHERE NOT EXISTS (
        SELECT 1
        FROM web_returns wr
        JOIN item i4 ON wr.wr_item_sk = i4.i_item_sk
        JOIN date_dim d4 ON wr.wr_returned_date_sk = d4.d_date_sk
        WHERE i4.i_brand = a.brand
          AND i4.i_category = a.category
          AND d4.d_year = 2000
    )
),
ranked_agg AS (
    SELECT
        brand,
        category,
        sum_sales,
        sum_return,
        sum_net_loss,
        row_cnt,
        ROW_NUMBER() OVER (PARTITION BY brand ORDER BY sum_sales DESC NULLS LAST) AS sales_rank
    FROM filtered_agg
)
SELECT
    brand,
    category,
    sum_sales,
    sum_return,
    sum_net_loss,
    sales_rank,
    (SELECT AVG(t.sum_sales) FROM filtered_agg t) AS avg_sum_sales_all_brands
FROM ranked_agg
WHERE sum_sales > 0 OR sum_return > 0
ORDER BY brand, category
LIMIT 100
