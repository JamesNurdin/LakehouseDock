-- Goal: Identify high‑selling items whose container description matches a pattern, whose product name starts with 'A', and that have never recorded a negative profit.  The query uses a CTE, string functions (regexp_like, regexp_extract, LIKE, substr), a scalar subquery for overall average net paid, and an anti‑join via NOT EXISTS.  Results are aggregated per item and ordered by total net paid (incl. tax).
WITH sales_item AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_paid_inc_tax,
        ss.ss_ext_wholesale_cost,
        i.i_item_id,
        i.i_product_name,
        i.i_container,
        i.i_category_id,
        -- Extract the first word of the container description for reporting
        regexp_extract(i.i_container, '^(\\w+)', 1) AS container_prefix
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_container, '(?i)box|case|package')      -- pattern match on container
      AND i.i_product_name LIKE 'A%'                           -- product name starts with A
)
SELECT
    si.i_item_id,
    si.i_product_name,
    si.i_container,
    si.container_prefix,
    si.i_category_id,
    SUM(si.ss_quantity) AS total_quantity_sold,
    SUM(si.ss_net_paid_inc_tax) AS total_net_paid_inc_tax,
    AVG(si.ss_ext_wholesale_cost) AS avg_ext_wholesale_cost,
    -- Show the first 10 characters of the product name for quick view
    substr(si.i_product_name, 1, 10) AS product_name_prefix,
    -- Compare against overall average net paid (scalar subquery)
    (SELECT avg(ss_net_paid_inc_tax) FROM store_sales) AS overall_avg_net_paid
FROM sales_item si
WHERE NOT EXISTS (
    SELECT 1
    FROM store_sales ss_neg
    WHERE ss_neg.ss_item_sk = si.ss_item_sk
      AND ss_neg.ss_net_profit < 0
)
GROUP BY
    si.i_item_id,
    si.i_product_name,
    si.i_container,
    si.container_prefix,
    si.i_category_id,
    si.ss_item_sk,
    si.ss_quantity,
    si.ss_net_paid_inc_tax,
    si.ss_ext_wholesale_cost
ORDER BY total_net_paid_inc_tax DESC
LIMIT 100
