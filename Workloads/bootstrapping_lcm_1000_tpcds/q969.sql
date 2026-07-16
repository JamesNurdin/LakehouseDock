WITH daily_sales AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_date_sk,
        d.d_year,
        d.d_quarter_name,
        hd.hd_income_band_sk,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_quantity,
        ss.ss_customer_sk,
        ss.ss_sales_price
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN date_dim cd ON s.s_closed_date_sk = cd.d_date_sk
    WHERE cd.d_date_sk IS NULL OR d.d_date_sk < cd.d_date_sk
),

daily_web AS (
    SELECT
        wp.wp_creation_date_sk AS d_date_sk,
        COUNT(DISTINCT wp.wp_web_page_sk) AS pages_created,
        SUM(wp.wp_image_count) AS total_images,
        SUM(wp.wp_link_count) AS total_links
    FROM web_page wp
    GROUP BY wp.wp_creation_date_sk
),

combined AS (
    SELECT
        ds.s_store_name,
        ds.d_year,
        ds.d_quarter_name,
        ds.hd_income_band_sk,
        ds.ss_ext_sales_price,
        ds.ss_ext_discount_amt,
        ds.ss_quantity,
        ds.ss_customer_sk,
        ds.ss_sales_price,
        dw.pages_created,
        dw.total_images,
        dw.total_links
    FROM daily_sales ds
    LEFT JOIN daily_web dw ON ds.d_date_sk = dw.d_date_sk
),

aggregated AS (
    SELECT
        c.s_store_name,
        c.d_year,
        c.d_quarter_name,
        c.hd_income_band_sk,
        SUM(c.ss_ext_sales_price) AS total_sales,
        SUM(c.ss_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT c.ss_customer_sk) AS distinct_customers,
        AVG(c.ss_sales_price) AS avg_sales_price,
        SUM(c.ss_quantity) AS total_quantity,
        SUM(COALESCE(c.pages_created, 0)) AS total_pages_created,
        SUM(COALESCE(c.total_images, 0)) AS total_images,
        SUM(COALESCE(c.total_links, 0)) AS total_links,
        (SUM(c.ss_ext_sales_price) - SUM(c.ss_ext_discount_amt)) / NULLIF(SUM(c.ss_ext_sales_price), 0) AS net_margin
    FROM combined c
    GROUP BY c.s_store_name, c.d_year, c.d_quarter_name, c.hd_income_band_sk
    HAVING SUM(c.ss_ext_sales_price) > 200000
)

SELECT
    a.*,
    ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_sales DESC) AS sales_rank_by_year
FROM aggregated a
ORDER BY a.total_sales DESC
LIMIT 100
