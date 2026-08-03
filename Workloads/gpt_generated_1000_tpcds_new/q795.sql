WITH
    -- Items that appear in both catalog_sales and store_sales
    intersect_items AS (
        SELECT cs_item_sk AS item_sk FROM catalog_sales
        INTERSECT
        SELECT ss_item_sk FROM store_sales
    ),
    -- Sampled full outer join between catalog_sales and date_dim (keeps unmatched rows)
    sampled_full AS (
        SELECT cs.cs_order_number,
               cs.cs_net_paid,
               d.d_date,
               d.d_year
        FROM (SELECT * FROM catalog_sales TABLESAMPLE BERNOULLI (5)) cs
        FULL OUTER JOIN date_dim d
            ON cs.cs_sold_date_sk = d.d_date_sk
    ),
    -- Aggregation from catalog_sales with regex filtering on item description
    catalog_agg AS (
        SELECT i.i_item_id,
               i.i_product_name,
               COUNT(*) AS sales_cnt,
               SUM(cs.cs_net_profit) AS total_profit,
               regexp_extract(i.i_item_desc, '(\\d{3})', 1) AS extracted_code
        FROM catalog_sales cs
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        WHERE cs.cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2002)
          AND regexp_like(i.i_item_desc, '^.*[A-Z]{2}.*$')
        GROUP BY i.i_item_id, i.i_product_name, i.i_item_desc
    ),
    -- Aggregation from store_sales with LIKE pattern on item description
    store_agg AS (
        SELECT i.i_item_id,
               i.i_product_name,
               COUNT(*) AS sales_cnt,
               SUM(ss.ss_net_profit) AS total_profit,
               substr(i.i_item_desc, 1, 10) AS desc_prefix
        FROM store_sales ss
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        WHERE ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2002)
          AND i.i_item_desc LIKE '%blue%'
        GROUP BY i.i_item_id, i.i_product_name, i.i_item_desc
    ),
    -- Union of the two channel aggregates (distinct rows)
    union_agg AS (
        SELECT i_item_id,
               i_product_name,
               sales_cnt,
               total_profit
        FROM catalog_agg
        UNION
        SELECT i_item_id,
               i_product_name,
               sales_cnt,
               total_profit
        FROM store_agg
    )
SELECT ua.i_item_id,
       ua.i_product_name,
       SUM(ua.sales_cnt) AS total_sales_cnt,
       SUM(ua.total_profit) AS total_profit,
       COUNT(DISTINCT ii.item_sk) AS common_item_cnt,
       (SELECT COUNT(*) FROM sampled_full) AS sampled_full_rows
FROM union_agg ua
JOIN item i ON i.i_item_id = ua.i_item_id
JOIN intersect_items ii ON i.i_item_sk = ii.item_sk
GROUP BY ua.i_item_id, ua.i_product_name
ORDER BY total_profit DESC
LIMIT 100
