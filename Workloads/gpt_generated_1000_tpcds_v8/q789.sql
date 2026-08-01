WITH
    filtered_items AS (
        SELECT i_item_sk,
               i_item_desc,
               i_category,
               regexp_extract(i_item_desc, '(\\d{2})', 1) AS two_digit_code
        FROM item
        WHERE regexp_like(i_item_desc, '\\d{2}')
    ),
    sampled_store_sales AS (
        SELECT ss_sold_time_sk,
               ss_item_sk,
               ss_quantity,
               ss_net_paid
        FROM store_sales
        TABLESAMPLE BERNOULLI (5)
        WHERE ss_item_sk IN (SELECT i_item_sk FROM filtered_items)
    ),
    sales_time AS (
        SELECT s.ss_item_sk,
               s.ss_quantity,
               s.ss_net_paid,
               t.t_shift,
               t.t_hour
        FROM sampled_store_sales s
        JOIN time_dim t
          ON s.ss_sold_time_sk = t.t_time_sk
        WHERE t.t_shift LIKE 'second%'
    ),
    sales_with_desc AS (
        SELECT st.*,
               i.i_item_desc,
               concat(i.i_brand, ' - ', i.i_category) AS brand_category
        FROM sales_time st
        CROSS JOIN LATERAL (
            SELECT i_item_desc, i_brand, i_category
            FROM item i
            WHERE i.i_item_sk = st.ss_item_sk
              AND regexp_like(i.i_item_desc, '^.*[A-Z]{3}.*$')
        ) i
    ),
    catalog_branch AS (
        SELECT cs.cs_item_sk,
               cs.cs_ext_sales_price,
               cc.cc_city,
               cp.cp_description,
               t.t_shift
        FROM catalog_sales cs
        JOIN call_center cc
          ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp
          ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN time_dim t
          ON cs.cs_sold_time_sk = t.t_time_sk
        WHERE cc.cc_city LIKE '%Hill%'
          AND regexp_like(cp.cp_description, '.*promo.*')
    ),
    union_branch AS (
        SELECT ss_item_sk AS item_sk,
               ss_net_paid AS metric,
               brand_category AS info
        FROM sales_with_desc
        UNION
        SELECT cs_item_sk AS item_sk,
               cs_ext_sales_price AS metric,
               concat(cc_city, ' - ', cp_description) AS info
        FROM catalog_branch
    ),
    intersect_items AS (
        SELECT item_sk FROM union_branch
        INTERSECT
        SELECT i_item_sk FROM filtered_items
    )
SELECT ub.item_sk,
       ub.metric,
       ub.info,
       COUNT(*) OVER (PARTITION BY ub.item_sk) AS row_cnt,
       AVG(ub.metric) OVER (PARTITION BY ub.item_sk) AS avg_metric,
       (SELECT SUM(metric) FROM union_branch) AS total_metric_all_items
FROM union_branch ub
WHERE ub.item_sk IN (SELECT item_sk FROM intersect_items)
ORDER BY avg_metric DESC
OFFSET 10
LIMIT 100
