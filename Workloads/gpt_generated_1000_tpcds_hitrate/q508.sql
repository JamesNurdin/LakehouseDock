WITH filtered_items AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        i.i_class,
        CONCAT(i.i_brand, '-', i.i_category) AS brand_category,
        regexp_extract(i.i_product_name, '^([^ ]+)', 1) AS first_word
    FROM tpcds.item i
    TABLESAMPLE BERNOULLI (10)
    WHERE regexp_like(i.i_product_name, '(?i)st')
      AND i.i_brand LIKE '%A%'
),
store_agg AS (
    SELECT
        fi.brand_category,
        SUM(ss.ss_net_paid) AS store_net_paid,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_count
    FROM filtered_items fi
    JOIN tpcds.store_sales ss
        ON ss.ss_item_sk = fi.i_item_sk
    GROUP BY fi.brand_category
),
catalog_agg AS (
    SELECT
        fi.brand_category,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT cc.cc_name) AS distinct_call_centers
    FROM filtered_items fi
    JOIN tpcds.catalog_sales cs
        ON cs.cs_item_sk = fi.i_item_sk
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_country = 'United States'
      AND cc.cc_rec_start_date <= DATE '2002-01-01'
    GROUP BY fi.brand_category
)
SELECT
    COALESCE(s.brand_category, c.brand_category) AS brand_category,
    COALESCE(s.store_net_paid, 0) AS store_net_paid,
    COALESCE(c.catalog_net_paid, 0) AS catalog_net_paid,
    (COALESCE(s.store_net_paid, 0) + COALESCE(c.catalog_net_paid, 0)) AS total_net_paid,
    CASE
        WHEN (COALESCE(s.store_net_paid, 0) + COALESCE(c.catalog_net_paid, 0)) > 100000 THEN 'HIGH'
        ELSE 'NORMAL'
    END AS revenue_level,
    COALESCE(s.store_txn_count, 0) AS store_txn_count,
    COALESCE(c.catalog_order_count, 0) AS catalog_order_count,
    COALESCE(c.distinct_call_centers, 0) AS distinct_call_centers
FROM store_agg s
FULL OUTER JOIN catalog_agg c
    ON s.brand_category = c.brand_category
ORDER BY total_net_paid DESC
LIMIT 50
