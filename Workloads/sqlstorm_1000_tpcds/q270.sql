WITH date_filter AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2002
      AND (mod(d_month_seq, 2) = 0 OR d_holiday = 'Y')
),
max_date AS (
    SELECT max(d_date_sk) AS max_date_sk
    FROM date_filter
),
sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        SUM(CASE WHEN cs.cs_item_sk IS NOT NULL THEN cs.cs_ext_sales_price ELSE 0 END) AS catalog_sales,
        SUM(CASE WHEN ss.ss_item_sk IS NOT NULL THEN ss.ss_ext_sales_price ELSE 0 END) AS store_sales,
        SUM(CASE WHEN ws.ws_item_sk IS NOT NULL THEN ws.ws_ext_sales_price ELSE 0 END) AS web_sales,
        COUNT(DISTINCT CASE WHEN cs.cs_item_sk IS NOT NULL THEN cs.cs_bill_customer_sk END) AS catalog_customers,
        COUNT(DISTINCT CASE WHEN ss.ss_item_sk IS NOT NULL THEN ss.ss_customer_sk END) AS store_customers,
        COUNT(DISTINCT CASE WHEN ws.ws_item_sk IS NOT NULL THEN ws.ws_bill_customer_sk END) AS web_customers
    FROM item i
    LEFT JOIN catalog_sales cs
        ON i.i_item_sk = cs.cs_item_sk
        AND cs.cs_sold_date_sk IN (SELECT d_date_sk FROM date_filter)
    LEFT JOIN store_sales ss
        ON i.i_item_sk = ss.ss_item_sk
        AND ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_filter)
    LEFT JOIN web_sales ws
        ON i.i_item_sk = ws.ws_item_sk
        AND ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_filter)
    GROUP BY i.i_item_sk, i.i_product_name, i.i_category, i.i_brand
),
returns_agg AS (
    SELECT
        COALESCE(cr.cr_item_sk, sr.sr_item_sk, wr.wr_item_sk) AS item_sk,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS catalog_returns,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS store_returns,
        SUM(COALESCE(wr.wr_return_amt, 0)) AS web_returns
    FROM catalog_returns cr
    FULL OUTER JOIN store_returns sr
        ON cr.cr_item_sk = sr.sr_item_sk
    FULL OUTER JOIN web_returns wr
        ON COALESCE(cr.cr_item_sk, sr.sr_item_sk) = wr.wr_item_sk
    GROUP BY COALESCE(cr.cr_item_sk, sr.sr_item_sk, wr.wr_item_sk)
),
item_detail AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        i.i_manufact,
        i.i_size,
        i.i_color,
        i.i_units,
        i.i_current_price,
        p.p_promo_name,
        p.p_discount_active
    FROM item i
    LEFT JOIN promotion p
        ON i.i_item_sk = p.p_item_sk
        AND p.p_start_date_sk <= (SELECT max_date_sk FROM max_date)
        AND p.p_end_date_sk >= (SELECT max_date_sk FROM max_date)
),
combined_agg AS (
    SELECT
        COALESCE(sa.i_item_sk, ra.item_sk) AS item_sk,
        COALESCE(sa.i_product_name, id.i_product_name) AS product_name,
        COALESCE(sa.i_category, id.i_category) AS category,
        COALESCE(sa.i_brand, id.i_brand) AS brand,
        COALESCE(sa.catalog_sales, 0) + COALESCE(sa.store_sales, 0) + COALESCE(sa.web_sales, 0) AS total_sales,
        COALESCE(ra.catalog_returns, 0) + COALESCE(ra.store_returns, 0) + COALESCE(ra.web_returns, 0) AS total_returns,
        COALESCE(sa.catalog_customers, 0) + COALESCE(sa.store_customers, 0) + COALESCE(sa.web_customers, 0) AS total_customers,
        id.p_promo_name,
        id.p_discount_active
    FROM sales_agg sa
    FULL OUTER JOIN returns_agg ra ON sa.i_item_sk = ra.item_sk
    LEFT JOIN item_detail id ON COALESCE(sa.i_item_sk, ra.item_sk) = id.i_item_sk
),
ranked_items AS (
    SELECT
        ca.*,
        CASE
            WHEN ca.total_sales = 0 THEN NULL
            ELSE ca.total_returns / nullif(ca.total_sales, 0)
        END AS return_rate,
        ROW_NUMBER() OVER (PARTITION BY ca.category ORDER BY ca.total_sales DESC) AS category_rank,
        ROW_NUMBER() OVER (ORDER BY ca.total_sales DESC) AS overall_rank,
        SUM(ca.total_sales) OVER (ORDER BY ca.total_sales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales
    FROM combined_agg ca
)

SELECT
    ri.item_sk,
    ri.product_name,
    ri.category,
    ri.brand,
    ri.total_sales,
    ri.total_returns,
    ri.return_rate,
    ri.overall_rank,
    ri.category_rank,
    ri.cumulative_sales,
    (SELECT MAX(cs2.cs_sales_price)
     FROM catalog_sales cs2
     WHERE cs2.cs_item_sk = ri.item_sk
       AND cs2.cs_sold_date_sk > (SELECT max_date_sk FROM max_date)) AS max_future_price,
    CONCAT(ri.brand, ': ', ri.product_name) AS full_name,
    ri.p_promo_name,
    CASE WHEN ri.p_discount_active = 'Y' THEN true ELSE false END AS promo_active_flag
FROM ranked_items ri
WHERE ri.overall_rank <= 5

UNION ALL

SELECT
    ri.item_sk,
    ri.product_name,
    ri.category,
    ri.brand,
    ri.total_sales,
    ri.total_returns,
    ri.return_rate,
    ri.overall_rank,
    ri.category_rank,
    ri.cumulative_sales,
    (SELECT MAX(cs2.cs_sales_price)
     FROM catalog_sales cs2
     WHERE cs2.cs_item_sk = ri.item_sk
       AND cs2.cs_sold_date_sk > (SELECT max_date_sk FROM max_date)) AS max_future_price,
    CONCAT(ri.brand, ': ', ri.product_name) AS full_name,
    ri.p_promo_name,
    CASE WHEN ri.p_discount_active = 'Y' THEN true ELSE false END AS promo_active_flag
FROM ranked_items ri
WHERE ri.return_rate > 0.5 AND ri.return_rate IS NOT NULL

EXCEPT

SELECT
    ri.item_sk,
    ri.product_name,
    ri.category,
    ri.brand,
    ri.total_sales,
    ri.total_returns,
    ri.return_rate,
    ri.overall_rank,
    ri.category_rank,
    ri.cumulative_sales,
    (SELECT MAX(cs2.cs_sales_price)
     FROM catalog_sales cs2
     WHERE cs2.cs_item_sk = ri.item_sk
       AND cs2.cs_sold_date_sk > (SELECT max_date_sk FROM max_date)) AS max_future_price,
    CONCAT(ri.brand, ': ', ri.product_name) AS full_name,
    ri.p_promo_name,
    CASE WHEN ri.p_discount_active = 'Y' THEN true ELSE false END AS promo_active_flag
FROM ranked_items ri
WHERE ri.brand IS NULL OR ri.category IS NULL
