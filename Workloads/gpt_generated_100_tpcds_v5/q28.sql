WITH base AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        inv.inv_quantity_on_hand,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cp.cp_catalog_page_id,
        cp.cp_type,
        s.s_store_id,
        s.s_store_name,
        s.s_division_id
    FROM inventory inv
    INNER JOIN item i
        ON inv.inv_item_sk = i.i_item_sk
    INNER JOIN date_dim d
        ON inv.inv_date_sk = d.d_date_sk
    INNER JOIN customer c
        ON c.c_first_sales_date_sk = d.d_date_sk
    INNER JOIN catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    LEFT OUTER JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
      AND inv.inv_quantity_on_hand > 0
      AND s.s_division_id IN (1, 2, 3)
      AND cp.cp_type = 'A'
),
aggregated AS (
    SELECT
        i_item_id,
        i_category,
        s_store_id,
        s_store_name,
        SUM(inv_quantity_on_hand) AS total_qty,
        COUNT(DISTINCT c_customer_id) AS distinct_customers
    FROM base
    GROUP BY i_item_id, i_category, s_store_id, s_store_name
)
SELECT
    a.i_category,
    AVG(a.total_qty) AS avg_qty_per_store,
    MAX(a.total_qty) AS max_qty_per_item,
    (SELECT COUNT(*) FROM store WHERE s_division_id = 1) AS division_one_store_count
FROM aggregated a
WHERE a.distinct_customers >= 5
GROUP BY a.i_category
HAVING AVG(a.total_qty) > 100
