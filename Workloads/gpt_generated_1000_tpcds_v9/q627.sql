-- goal: Combine inventory quantities and sales totals by year, filter rows using regexp and pattern matching on catalog page descriptions and warehouse IDs, union the two result sets, rank amounts within each source, and return the top 100 rows.
WITH inv_full AS (
    SELECT inv.inv_item_sk,
           inv.inv_quantity_on_hand,
           dim.d_year
    FROM inventory inv
    FULL OUTER JOIN date_dim dim
        ON inv.inv_date_sk = dim.d_date_sk
    WHERE inv.inv_quantity_on_hand > 0
),
sales_agg AS (
    SELECT dim.d_year AS year,
           regexp_extract(cp.cp_description, '([A-Za-z]+)', 1) AS first_word,
           sum(cs.cs_net_paid) AS total_sales
    FROM catalog_sales cs
    JOIN date_dim dim
        ON cs.cs_sold_date_sk = dim.d_date_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE regexp_like(cp.cp_description, '(?i)intensive|economic')
      AND w.w_warehouse_id LIKE 'AAAA%'
      AND substring(w.w_warehouse_id, 1, 4) = 'AAAA'
    GROUP BY dim.d_year, regexp_extract(cp.cp_description, '([A-Za-z]+)', 1)
),
union_set AS (
    SELECT COALESCE(i.d_year, -1) AS year,
           'inventory' AS source,
           CAST(i.inv_item_sk AS VARCHAR) AS key,
           CAST(i.inv_quantity_on_hand AS DOUBLE) AS amount
    FROM inv_full i

    UNION

    SELECT s.year,
           'sales' AS source,
           s.first_word AS key,
           CAST(s.total_sales AS DOUBLE) AS amount
    FROM sales_agg s
)
SELECT year,
       source,
       key,
       amount,
       concat(source, '-', key) AS key_label,
       substring(key, 1, 5) AS key_prefix,
       row_number() OVER (PARTITION BY source ORDER BY amount DESC) AS rn
FROM union_set
ORDER BY year DESC, source, amount DESC
LIMIT 100
