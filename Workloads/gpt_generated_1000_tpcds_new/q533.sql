WITH
    high_profit_orders AS (
        SELECT cs_order_number
        FROM catalog_sales
        WHERE cs_net_profit > 1000
    ),
    low_profit_orders AS (
        SELECT cs_order_number
        FROM catalog_sales
        WHERE cs_net_profit <= 100
    ),
    profit_order_diff AS (
        SELECT cs_order_number
        FROM high_profit_orders
        EXCEPT
        SELECT cs_order_number
        FROM low_profit_orders
    ),
    store_sales_agg AS (
        SELECT
            ss.ss_store_sk,
            d.d_year AS sales_year,
            SUM(ss.ss_net_paid) AS total_net_paid,
            COUNT(*) AS sales_cnt,
            MIN(ss.ss_sold_date_sk) AS first_date_sk
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2002-12-31'
        GROUP BY ss.ss_store_sk, d.d_year
    ),
    web_page_parts AS (
        SELECT
            wp.wp_web_page_sk,
            wp.wp_url,
            segment,
            seq,
            ROW_NUMBER() OVER (PARTITION BY wp.wp_web_page_sk ORDER BY seq) AS segment_rank
        FROM web_page wp
        CROSS JOIN UNNEST(split(wp.wp_url, '/')) WITH ORDINALITY AS t(segment, seq)
        WHERE wp.wp_url LIKE 'http://%'
          AND REGEXP_LIKE(wp.wp_url, '^http://.*\\.com')
    ),
    combined AS (
        SELECT
            ssagg.ss_store_sk,
            ssagg.sales_year,
            ssagg.total_net_paid,
            wp_parts.wp_web_page_sk,
            wp_parts.segment,
            wp_parts.segment_rank,
            CONCAT('Store ', CAST(ssagg.ss_store_sk AS VARCHAR)) AS store_label
        FROM store_sales_agg ssagg
        FULL OUTER JOIN web_page_parts wp_parts
            ON ssagg.ss_store_sk = wp_parts.wp_web_page_sk
    )
SELECT
    pod.cs_order_number,
    comb.ss_store_sk,
    comb.sales_year,
    comb.total_net_paid,
    comb.wp_web_page_sk,
    comb.segment,
    comb.segment_rank,
    comb.store_label,
    REGEXP_EXTRACT(comb.segment, '([^\\.]+)\\.com', 1) AS extracted_domain_part
FROM profit_order_diff pod
LEFT JOIN combined comb
    ON pod.cs_order_number = comb.ss_store_sk
WHERE comb.segment_rank IS NOT NULL
ORDER BY comb.total_net_paid DESC NULLS LAST
LIMIT 100
