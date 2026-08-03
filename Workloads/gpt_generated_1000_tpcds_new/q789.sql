WITH cs_filtered AS (
    SELECT
        cs.cs_sold_time_sk AS time_sk,
        cs.cs_ext_sales_price,
        p.p_promo_name,
        CONCAT('Promo:', p.p_promo_name) AS promo_label,
        CASE WHEN regexp_like(p.p_promo_name, '(?i)discount') THEN 1 ELSE 0 END AS is_discount
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE regexp_like(p.p_promo_name, '(?i)discount')
),
cs_agg AS (
    SELECT
        time_sk,
        COUNT(*) AS sales_cnt,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(is_discount) AS discount_sales_cnt,
        MAX(promo_label) AS any_promo_label
    FROM cs_filtered
    GROUP BY time_sk
),
wr_join AS (
    SELECT
        wr.wr_returned_time_sk AS time_sk,
        wr.wr_return_amt,
        wp.wp_url,
        wp.wp_type
    FROM web_returns wr
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_url LIKE '%/promo%'
      AND regexp_like(wp.wp_type, '^blog')
),
wr_agg AS (
    SELECT
        time_sk,
        COUNT(*) AS returns_cnt,
        SUM(wr_return_amt) AS total_returns
    FROM wr_join
    GROUP BY time_sk
)
SELECT
    COALESCE(cs.time_sk, wr.time_sk) AS time_sk,
    cs.sales_cnt,
    cs.total_sales,
    cs.discount_sales_cnt,
    wr.returns_cnt,
    wr.total_returns,
    cs.any_promo_label
FROM cs_agg cs
FULL OUTER JOIN wr_agg wr
    ON cs.time_sk = wr.time_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM store_returns sr
    WHERE sr.sr_return_time_sk = COALESCE(cs.time_sk, wr.time_sk)
)
ORDER BY time_sk
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
