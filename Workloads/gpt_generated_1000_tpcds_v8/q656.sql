WITH full_items_pages AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        cp.cp_catalog_page_sk,
        cp.cp_catalog_page_id,
        cp.cp_department
    FROM item i
    FULL OUTER JOIN catalog_page cp
        ON 1 = 0
),

returns_detail AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_item_sk,
        cr.cr_catalog_page_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        i.i_brand,
        i.i_category,
        i.i_item_desc,
        cp.cp_department,
        cp.cp_catalog_page_number
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cr.cr_return_amount > 50.00
      AND i.i_current_price BETWEEN 10 AND 100
      AND cp.cp_department LIKE '%Clothing%'
),

lost_items AS (
    SELECT DISTINCT cr_item_sk
    FROM returns_detail
    WHERE cr_net_loss > 0
),

non_bar_items AS (
    SELECT i_item_sk
    FROM item
    WHERE i_brand <> 'Barcallyable'
),

excluded_items AS (
    SELECT cr_item_sk
    FROM lost_items
    EXCEPT
    SELECT i_item_sk
    FROM non_bar_items
),

ranked_returns AS (
    SELECT
        rd.cr_returned_date_sk,
        rd.cr_item_sk,
        rd.i_brand,
        rd.i_category,
        rd.cp_department,
        rd.cr_return_quantity,
        rd.cr_return_amount,
        rd.cr_net_loss,
        ROW_NUMBER() OVER (PARTITION BY rd.i_brand ORDER BY rd.cr_return_amount DESC) AS brand_return_rank,
        RANK() OVER (ORDER BY rd.cr_net_loss DESC) AS net_loss_rank,
        word,
        ROW_NUMBER() OVER (PARTITION BY rd.cr_item_sk ORDER BY word) AS word_seq
    FROM returns_detail rd
    CROSS JOIN UNNEST(split(rd.i_item_desc, ' ')) AS t(word)
    WHERE rd.cr_item_sk NOT IN (SELECT cr_item_sk FROM excluded_items)
)

SELECT
    rr.cr_returned_date_sk,
    rr.cr_item_sk,
    rr.i_brand,
    rr.i_category,
    rr.cp_department,
    rr.cr_return_quantity,
    rr.cr_return_amount,
    rr.cr_net_loss,
    rr.brand_return_rank,
    rr.net_loss_rank,
    rr.word,
    rr.word_seq
FROM ranked_returns rr
ORDER BY rr.net_loss_rank ASC, rr.brand_return_rank ASC
LIMIT 100
