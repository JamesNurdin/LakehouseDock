WITH filtered_sales AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_net_paid_inc_tax,
        cs.cs_net_profit,
        cs.cs_order_number,
        cs.cs_sales_price,
        i.i_brand,
        i.i_category,
        i.i_container,
        i.i_class_id,
        i.i_manager_id,
        cs.cs_promo_sk,
        cs.cs_ship_cdemo_sk
    FROM
        catalog_sales cs
        JOIN item i
            ON cs.cs_item_sk = i.i_item_sk
    WHERE
        cs.cs_promo_sk IN (165, 1023, 878)                     -- predicate 1
        AND cs.cs_ship_cdemo_sk NOT IN (3755, 90299)           -- predicate 2
        AND cs.cs_net_paid_inc_tax > 500.00                    -- predicate 3
        AND i.i_container NOT IN ('Unknown', 'Small Box')      -- predicate 4
        AND i.i_class_id IN (8, 10, 13, 16)                    -- predicate 5
        AND i.i_manager_id = 34                               -- predicate 6
),

brand_category_agg AS (
    SELECT
        i_brand,
        i_category,
        SUM(cs_net_paid_inc_tax) AS total_net_paid_inc_tax,
        SUM(cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs_order_number) AS distinct_orders,
        AVG(cs_sales_price) AS avg_sales_price,
        COUNT(DISTINCT cs_item_sk) AS distinct_items
    FROM
        filtered_sales
    GROUP BY
        i_brand,
        i_category
),

ranked_brands AS (
    SELECT
        i_brand,
        i_category,
        total_net_paid_inc_tax,
        total_profit,
        distinct_orders,
        avg_sales_price,
        distinct_items,
        ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS profit_rank
    FROM
        brand_category_agg
    WHERE
        total_net_paid_inc_tax > 10000
        AND total_profit > 0
)

SELECT
    rb.i_brand,
    rb.i_category,
    rb.total_net_paid_inc_tax,
    rb.total_profit,
    rb.distinct_orders,
    rb.avg_sales_price,
    rb.distinct_items,
    rb.profit_rank
FROM
    ranked_brands rb
WHERE NOT EXISTS (
    SELECT 1
    FROM (
        SELECT DISTINCT i_brand
        FROM item
        WHERE i_container = 'Small Box'
    ) sb
    WHERE sb.i_brand = rb.i_brand
)
ORDER BY
    rb.total_profit DESC
LIMIT 100
