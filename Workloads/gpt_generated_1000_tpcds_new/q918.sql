WITH
    filtered_sales AS (
        SELECT
            cs.cs_sold_date_sk,
            cs.cs_item_sk,
            cs.cs_net_paid_inc_tax,
            cs.cs_ext_list_price,
            cs.cs_quantity,
            cs.cs_net_profit
        FROM catalog_sales cs
        WHERE cs.cs_net_paid_inc_tax > 1000
          AND cs.cs_ext_list_price BETWEEN 2000 AND 5000
          AND cs.cs_quantity >= 2
          AND cs.cs_quantity > 0            -- additional selective predicate
          AND cs.cs_ext_discount_amt < 500  -- additional selective predicate
    ),
    item_intersect AS (
        SELECT cs1.cs_item_sk
        FROM filtered_sales cs1
        WHERE cs1.cs_quantity > 5
        INTERSECT
        SELECT cs2.cs_item_sk
        FROM filtered_sales cs2
        WHERE cs2.cs_net_profit > 500
    ),
    agg AS (
        SELECT
            d.d_year,
            i.i_category,
            i.i_brand,
            SUM(fs.cs_net_paid_inc_tax) AS total_paid_inc_tax,
            AVG(fs.cs_ext_list_price) AS avg_list_price,
            COUNT(DISTINCT fs.cs_item_sk) AS distinct_items,
            SUM(fs.cs_net_profit) AS total_profit
        FROM filtered_sales fs
        JOIN date_dim d ON fs.cs_sold_date_sk = d.d_date_sk
        JOIN item i ON fs.cs_item_sk = i.i_item_sk
        JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
        JOIN item_intersect ii ON fs.cs_item_sk = ii.cs_item_sk
        WHERE d.d_year BETWEEN 2000 AND 2002
          AND i.i_category_id IN (5, 8, 10)
          AND i.i_manufact_id = 460
          AND wp.wp_autogen_flag = 'N'
          AND wp.wp_max_ad_count >= 2
          AND wp.wp_max_ad_count <= 5            -- additional selective predicate
        GROUP BY GROUPING SETS (
            (d.d_year, i.i_category, i.i_brand),
            (i.i_category, i.i_brand),
            ()
        )
    )
SELECT
    d_year,
    i_category,
    i_brand,
    total_paid_inc_tax,
    avg_list_price,
    distinct_items,
    CASE
        WHEN total_profit > 10000 THEN 'HIGH'
        WHEN total_profit > 5000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_level,
    ROW_NUMBER() OVER (ORDER BY total_paid_inc_tax DESC) AS rn
FROM agg
ORDER BY total_paid_inc_tax DESC
OFFSET 0
LIMIT 100
