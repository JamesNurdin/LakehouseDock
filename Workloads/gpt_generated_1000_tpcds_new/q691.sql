WITH sampled_catalog_page AS (
    SELECT *
    FROM catalog_page TABLESAMPLE BERNOULLI (10)
),

returns_filtered AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_return_quantity,
        cr.cr_refunded_customer_sk,
        cr.cr_returning_customer_sk,
        cp.cp_description,
        i.i_brand,
        i.i_class,
        i.i_item_desc
    FROM catalog_returns cr
    JOIN sampled_catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    WHERE regexp_like(cp.cp_description, '(prisoners|officers)')
),

inventory_agg AS (
    SELECT
        inv.inv_item_sk AS item_sk,
        sum(inv.inv_quantity_on_hand) AS total_inventory_qty,
        concat(i.i_brand, '-', i.i_class) AS brand_class,
        regexp_extract(i.i_item_desc, '^([^ ]+)', 1) AS first_word_desc
    FROM inventory inv
    JOIN item i
        ON inv.inv_item_sk = i.i_item_sk
    GROUP BY inv.inv_item_sk, i.i_brand, i.i_class, i.i_item_desc
),

returns_agg AS (
    SELECT
        rf.cr_item_sk AS item_sk,
        sum(rf.cr_return_quantity) AS total_return_qty,
        count(DISTINCT rf.cr_refunded_customer_sk) AS distinct_refunded_cust,
        count(DISTINCT rf.cr_returning_customer_sk) AS distinct_returning_cust,
        concat(rf.i_brand, '-', rf.i_class) AS brand_class,
        regexp_extract(rf.i_item_desc, '^([^ ]+)', 1) AS first_word_desc,
        rf.cp_description AS page_desc
    FROM returns_filtered rf
    GROUP BY rf.cr_item_sk, rf.i_brand, rf.i_class, rf.i_item_desc, rf.cp_description
),

customer_refunded AS (
    SELECT DISTINCT cr_refunded_customer_sk AS cust_sk
    FROM returns_filtered
),

customer_returning AS (
    SELECT DISTINCT cr_returning_customer_sk AS cust_sk
    FROM returns_filtered
),

common_customers AS (
    SELECT cust_sk FROM customer_refunded
    INTERSECT
    SELECT cust_sk FROM customer_returning
),

final AS (
    SELECT
        coalesce(r.brand_class, i.brand_class) AS brand_class,
        coalesce(r.first_word_desc, i.first_word_desc) AS first_word_desc,
        coalesce(r.total_return_qty, 0) AS total_return_qty,
        coalesce(i.total_inventory_qty, 0) AS total_inventory_qty,
        r.distinct_refunded_cust,
        r.distinct_returning_cust
    FROM returns_agg r
    FULL OUTER JOIN inventory_agg i
        ON r.item_sk = i.item_sk
    WHERE (r.brand_class LIKE 'A%' OR i.brand_class LIKE 'A%')
)
SELECT
    brand_class,
    first_word_desc,
    substr(brand_class, 1, 5) AS brand_prefix,
    total_return_qty,
    total_inventory_qty,
    distinct_refunded_cust,
    distinct_returning_cust
FROM final
WHERE brand_class IS NOT NULL
ORDER BY total_return_qty DESC
LIMIT 100
