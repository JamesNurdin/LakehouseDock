WITH
    date_filtered AS (
        SELECT d_date_sk, d_year, d_month_seq, d_holiday
        FROM date_dim
        WHERE d_year = 2020
          AND d_month_seq BETWEEN 1 AND 12
          AND d_holiday = 'N'
    ),
    store_sales_join AS (
        SELECT ss.ss_sold_date_sk,
               ss.ss_item_sk,
               ss.ss_store_sk,
               ss.ss_quantity,
               ss.ss_sales_price,
               i.i_item_id,
               s.s_store_name,
               s.s_state,
               d.d_year
        FROM store_sales ss
        JOIN date_filtered d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        WHERE s.s_state = 'CA'
          AND i.i_brand = 'BrandX'
          AND NOT EXISTS (
              SELECT 1
              FROM catalog_sales cs
              WHERE cs.cs_item_sk = ss.ss_item_sk
                AND cs.cs_sold_date_sk = ss.ss_sold_date_sk
          )
    ),
    catalog_sales_join AS (
        SELECT cs.cs_sold_date_sk,
               cs.cs_item_sk,
               cs.cs_quantity,
               cs.cs_ext_discount_amt,
               i.i_item_id,
               cp.cp_type,
               cp.cp_department
        FROM catalog_sales cs
        JOIN date_filtered d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        WHERE cp.cp_type = 'C'
          AND cp.cp_department = 'Books'
    ),
    web_returns_join AS (
        SELECT wr.wr_returned_date_sk,
               wr.wr_item_sk,
               wr.wr_return_quantity,
               r.r_reason_desc,
               wp.wp_type
        FROM web_returns wr
        JOIN date_filtered d ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
        JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
        JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        WHERE r.r_reason_desc LIKE '%damaged%'
    ),
    inventory_join AS (
        SELECT inv.inv_date_sk,
               inv.inv_item_sk,
               inv.inv_quantity_on_hand,
               i.i_item_id
        FROM inventory inv
        JOIN date_filtered d ON inv.inv_date_sk = d.d_date_sk
        JOIN item i ON inv.inv_item_sk = i.i_item_sk
        WHERE inv.inv_quantity_on_hand > 0
    ),
    sold_items_union AS (
        SELECT ss_item_sk AS item_sk FROM store_sales_join
        UNION
        SELECT cs_item_sk FROM catalog_sales_join
    ),
    returned_items AS (
        SELECT wr_item_sk AS item_sk FROM web_returns_join
    ),
    net_sold_items AS (
        SELECT item_sk FROM sold_items_union
        EXCEPT
        SELECT item_sk FROM returned_items
    ),
    store_sales_agg AS (
        SELECT ss_item_sk,
               SUM(ss_quantity) AS total_qty,
               SUM(ss_sales_price) AS total_sales
        FROM store_sales_join
        GROUP BY ss_item_sk
    ),
    inventory_agg AS (
        SELECT inv_item_sk,
               SUM(inv_quantity_on_hand) AS total_on_hand
        FROM inventory_join
        GROUP BY inv_item_sk
    ),
    full_join_inv_sales AS (
        SELECT COALESCE(i.inv_item_sk, s.ss_item_sk) AS item_sk,
               i.total_on_hand,
               s.total_qty,
               s.total_sales
        FROM inventory_agg i
        FULL OUTER JOIN store_sales_agg s
            ON i.inv_item_sk = s.ss_item_sk
    ),
    store_year_sales AS (
        SELECT s.s_store_sk,
               s.s_store_name,
               d.d_year,
               SUM(ss.ss_sales_price) AS store_sales
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        WHERE d.d_year = 2020
        GROUP BY s.s_store_sk, s.s_store_name, d.d_year
    ),
    final AS (
        SELECT
            sy.s_store_name,
            sy.d_year,
            sy.store_sales,
            RANK() OVER (PARTITION BY sy.d_year ORDER BY sy.store_sales DESC) AS sales_rank,
            (SELECT AVG(cs_ext_discount_amt) FROM catalog_sales_join) AS avg_discount,
            (SELECT COUNT(*) FROM net_sold_items) AS net_sold_item_cnt
        FROM store_year_sales sy
    )
SELECT *
FROM final
ORDER BY sales_rank
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
