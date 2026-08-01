WITH
    /* Catalog sales filtered by a regex on the item description and a LIKE on the catalog page type */
    cat_sales AS (
        SELECT
            cs.cs_item_sk,
            i.i_item_desc,
            cp.cp_catalog_page_id,
            SUM(cs.cs_net_paid_inc_ship) AS total_net_paid,
            COUNT(*) AS cnt_sales
        FROM tpcds.catalog_sales cs
        JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
        JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        WHERE regexp_like(i.i_item_desc, '^.*[0-9]{2}.*$')
          AND cp.cp_type LIKE 'A%'
        GROUP BY cs.cs_item_sk, i.i_item_desc, cp.cp_catalog_page_id
    ),

    /* Store sales aggregated for items whose description contains the word SPORT and quantity > 5 */
    store_sales_agg AS (
        SELECT
            ss.ss_item_sk,
            i.i_item_desc,
            SUM(ss.ss_ext_sales_price) AS store_total,
            COUNT(*) AS cnt_store
        FROM tpcds.store_sales ss
        JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
        WHERE i.i_item_desc LIKE '%SPORT%'
          AND ss.ss_quantity > 5
        GROUP BY ss.ss_item_sk, i.i_item_desc
    ),

    /* Items that appear in both the previous CTEs */
    common_items AS (
        SELECT cs_item_sk FROM cat_sales
        INTERSECT
        SELECT ss_item_sk FROM store_sales_agg
    ),

    /* Items sold in the catalog that never appeared in a store return and are not in the common set */
    catalog_not_returned AS (
        SELECT cs.cs_item_sk
        FROM tpcds.catalog_sales cs
        WHERE cs.cs_item_sk NOT IN (
            SELECT sr.sr_item_sk FROM tpcds.store_returns sr
        )
        EXCEPT
        SELECT cs_item_sk FROM common_items
    ),

    /* Full outer join of items with store returns, pulling any catalog‑sales net paid if it exists */
    full_items AS (
        SELECT
            i.i_item_sk,
            i.i_item_desc,
            sr.sr_return_quantity,
            cs.cs_net_paid_inc_ship
        FROM tpcds.item i
        FULL OUTER JOIN tpcds.store_returns sr ON i.i_item_sk = sr.sr_item_sk
        LEFT JOIN tpcds.catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    ),

    /* Distinct set of item keys coming from two different sources */
    union_items AS (
        SELECT i.i_item_sk AS i_item_sk FROM tpcds.item i WHERE i.i_color = 'Red'
        UNION
        SELECT cs.cs_item_sk AS i_item_sk FROM tpcds.catalog_sales cs WHERE cs.cs_ext_discount_amt > 0
    ),

    /* Add a row number to the union set (partitioned by the key) */
    union_items_rn AS (
        SELECT
            i_item_sk,
            ROW_NUMBER() OVER (PARTITION BY i_item_sk ORDER BY i_item_sk) AS uni_rn
        FROM union_items
    ),

    /* Add a global row number to the full‑outer‑joined data */
    full_items_rn AS (
        SELECT
            i_item_sk,
            i_item_desc,
            sr_return_quantity,
            cs_net_paid_inc_ship,
            ROW_NUMBER() OVER (ORDER BY i_item_sk) AS global_rn
        FROM full_items
    )
SELECT
    fi.i_item_sk,
    fi.i_item_desc,
    COALESCE(fi.sr_return_quantity, 0) AS total_return_qty,
    COALESCE(fi.cs_net_paid_inc_ship, 0) AS catalog_net_paid,
    (SELECT AVG(cs.cs_net_paid_inc_ship)
     FROM tpcds.catalog_sales cs
     WHERE cs.cs_net_paid_inc_ship > 0) AS avg_catalog_net_paid,
    fi.global_rn,
    CASE
        WHEN regexp_extract(fi.i_item_desc, '(\\d+)', 1) IS NOT NULL
        THEN CAST(regexp_extract(fi.i_item_desc, '(\\d+)', 1) AS INTEGER)
        ELSE NULL
    END AS extracted_number
FROM full_items_rn fi
JOIN union_items_rn ur ON fi.i_item_sk = ur.i_item_sk
WHERE fi.i_item_desc IS NOT NULL
  AND fi.i_item_desc LIKE '%2023%'
ORDER BY fi.i_item_sk
