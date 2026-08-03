WITH
    sales_items AS (
        SELECT
            ss.ss_item_sk,
            i.i_item_id,
            i.i_category,
            ss.ss_ext_sales_price,
            ss.ss_store_sk,
            ss.ss_sold_date_sk
        FROM store_sales ss
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        WHERE ss.ss_ext_sales_price > 1000
    ),
    catalog_items AS (
        SELECT DISTINCT si.ss_item_sk AS item_sk
        FROM sales_items si
        WHERE EXISTS (
            SELECT 1
            FROM catalog_returns cr
            WHERE cr.cr_item_sk = si.ss_item_sk
              AND cr.cr_return_amount > 0
        )
    ),
    web_items AS (
        SELECT DISTINCT si.ss_item_sk AS item_sk
        FROM sales_items si
        WHERE EXISTS (
            SELECT 1
            FROM web_returns wr
            WHERE wr.wr_item_sk = si.ss_item_sk
              AND wr.wr_return_amt > 0
        )
    ),
    intersect_items AS (
        SELECT item_sk FROM catalog_items
        INTERSECT
        SELECT item_sk FROM web_items
    ),
    except_items AS (
        SELECT si.ss_item_sk AS item_sk
        FROM sales_items si
        EXCEPT
        SELECT item_sk FROM intersect_items
    ),
    combined_items AS (
        SELECT item_sk FROM intersect_items
        UNION ALL
        SELECT item_sk FROM except_items
    ),
    final_details AS (
        SELECT
            si.ss_item_sk,
            i.i_item_id,
            i.i_category,
            si.ss_ext_sales_price
        FROM sales_items si
        JOIN item i ON si.ss_item_sk = i.i_item_sk
        WHERE si.ss_item_sk IN (SELECT item_sk FROM combined_items)
    )
SELECT
    ROW_NUMBER() OVER (ORDER BY fd.ss_ext_sales_price DESC) AS row_num,
    fd.i_item_id AS item_id,
    fd.i_category AS category,
    fd.ss_ext_sales_price AS sales_price
FROM final_details fd
ORDER BY fd.ss_ext_sales_price DESC
LIMIT 100
