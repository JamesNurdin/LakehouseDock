WITH
sales_per_store_item AS (
    SELECT
        ss.ss_store_id AS store_id,
        ss.ss_item_id AS item_id,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
    FROM store_sales ss
    GROUP BY ss.ss_store_id, ss.ss_item_id
),

review_agg AS (
    SELECT
        pr.pr_item_id AS item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),

item_info AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_price,
        i.i_category,
        i.i_category_id
    FROM items i
),

distinct_customers_per_store AS (
    SELECT
        ss.ss_store_id AS store_id,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
    FROM store_sales ss
    GROUP BY ss.ss_store_id
),

sales_agg AS (
    SELECT
        spi.store_id,
        SUM(spi.total_quantity) AS total_quantity_sold,
        AVG(ii.i_price) AS avg_item_price,
        AVG(r.avg_sentiment) AS avg_review_sentiment
    FROM sales_per_store_item spi
    JOIN item_info ii
        ON ii.item_id = spi.item_id
    LEFT JOIN review_agg r
        ON r.item_id = spi.item_id
    GROUP BY spi.store_id
)

SELECT
    s.s_store_name AS store_name,
    COALESCE(sa.total_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(sa.avg_item_price, 0) AS avg_item_price,
    sa.avg_review_sentiment,
    COALESCE(dcs.distinct_customers, 0) AS distinct_customers
FROM stores s
LEFT JOIN sales_agg sa
    ON sa.store_id = s.s_store_id
LEFT JOIN distinct_customers_per_store dcs
    ON dcs.store_id = s.s_store_id
ORDER BY total_quantity_sold DESC
LIMIT 10
