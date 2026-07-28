/* goal: Identify the top 10 products whose names match specific patterns, enriched with active email promotions, and compute net sales after subtracting store and web returns */
WITH sales AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_manufact_id,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS sales_cnt
    FROM tpcds.catalog_sales cs
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    /* product name contains three letters followed by two digits, e.g., ABC12 */
    WHERE regexp_like(i.i_product_name, '[A-Z]{3}[0-9]{2}')
    GROUP BY i.i_item_sk, i.i_product_name, i.i_manufact_id
),
store_ret AS (
    SELECT
        sr.sr_item_sk,
        SUM(sr.sr_return_amt) AS total_store_return,
        COUNT(*) AS store_ret_cnt
    FROM tpcds.store_returns sr
    GROUP BY sr.sr_item_sk
),
web_ret AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_amt) AS total_web_return,
        COUNT(*) AS web_ret_cnt
    FROM tpcds.web_returns wr
    GROUP BY wr.wr_item_sk
),
promo AS (
    SELECT
        p.p_item_sk,
        p.p_promo_name,
        p.p_channel_email
    FROM tpcds.promotion p
    WHERE p.p_channel_email = 'Y'
)
SELECT
    s.i_product_name,
    s.i_manufact_id,
    p.p_promo_name,
    CONCAT(SUBSTRING(s.i_product_name, 1, 10), '_', CAST(s.i_manufact_id AS VARCHAR)) AS product_key,
    s.total_sales,
    COALESCE(sr.total_store_return, 0) AS total_store_return,
    COALESCE(wr.total_web_return, 0) AS total_web_return,
    s.total_sales - COALESCE(sr.total_store_return, 0) - COALESCE(wr.total_web_return, 0) AS net_sales
FROM sales s
LEFT JOIN store_ret sr ON s.i_item_sk = sr.sr_item_sk
LEFT JOIN web_ret wr ON s.i_item_sk = wr.wr_item_sk
LEFT JOIN promo p ON s.i_item_sk = p.p_item_sk
WHERE regexp_like(s.i_product_name, '^.*[A-Z]{2}[0-9]{3}.*$')
  AND s.i_product_name LIKE '%PROD%'
ORDER BY net_sales DESC
LIMIT 10
