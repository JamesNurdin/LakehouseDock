WITH
    filtered_sales AS (
        SELECT
            cs.cs_item_sk,
            i.i_product_name,
            i.i_brand,
            cs.cs_quantity,
            cs.cs_ext_sales_price,
            cs.cs_net_profit,
            cs.cs_sold_date_sk,
            d.d_year,
            cp.cp_description
        FROM catalog_sales cs
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        WHERE regexp_like(cp.cp_description, '(?i)store')
          AND i.i_product_name LIKE '%Eco%'
          AND d.d_year = 2001
    ),
    sales_agg AS (
        SELECT
            cs_item_sk,
            MAX(i_product_name) AS i_product_name,
            MAX(i_brand) AS i_brand,
            SUM(cs_quantity) AS total_quantity,
            SUM(cs_ext_sales_price) AS total_sales,
            SUM(cs_net_profit) AS total_profit
        FROM filtered_sales
        GROUP BY cs_item_sk
    ),
    returns AS (
        SELECT DISTINCT sr_item_sk
        FROM store_returns
    ),
    items_no_returns AS (
        SELECT cs_item_sk
        FROM sales_agg
        EXCEPT
        SELECT sr_item_sk
        FROM returns
    ),
    item_warehouses AS (
        SELECT DISTINCT cs_item_sk, cs_warehouse_sk
        FROM catalog_sales
    ),
    final_items AS (
        SELECT
            sa.cs_item_sk,
            sa.i_product_name,
            sa.i_brand,
            sa.total_quantity,
            sa.total_sales,
            sa.total_profit
        FROM sales_agg sa
        JOIN items_no_returns ino ON sa.cs_item_sk = ino.cs_item_sk
    )
SELECT
    fi.cs_item_sk,
    fi.i_product_name,
    fi.i_brand,
    fi.total_quantity,
    fi.total_sales,
    fi.total_profit,
    RANK() OVER (ORDER BY fi.total_profit DESC) AS profit_rank,
    CONCAT('Item_', CAST(fi.cs_item_sk AS varchar)) AS item_label,
    CASE
        WHEN regexp_extract(fi.i_product_name, '(Eco.*)') IS NOT NULL THEN regexp_extract(fi.i_product_name, '(Eco.*)')
        ELSE fi.i_product_name
    END AS eco_product_name,
    (SELECT AVG(total_profit) FROM sales_agg) AS avg_profit_all_items,
    (SELECT COUNT(*) FROM item_warehouses iw WHERE iw.cs_item_sk = fi.cs_item_sk) AS warehouse_count
FROM final_items fi
WHERE NOT EXISTS (
    SELECT 1
    FROM reason r
    WHERE r.r_reason_id = 'UNKNOWN'
      AND r.r_reason_desc LIKE '%damage%'
)
ORDER BY fi.total_profit DESC, fi.cs_item_sk
LIMIT 100
