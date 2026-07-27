WITH sales_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_catalog_page_sk,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt
    FROM tpcds.catalog_sales cs
    GROUP BY cs.cs_item_sk, cs.cs_catalog_page_sk
)
SELECT
    cp.cp_catalog_page_id,
    i.i_item_id,
    i.i_brand,
    i.i_category,
    cr.cr_return_amount,
    cr.cr_net_loss,
    wr.wr_return_amt,
    wr.wr_net_loss,
    wp.wp_url,
    wp.wp_image_count,
    sa.total_net_paid,
    sa.sales_cnt,
    (SELECT AVG(cr2.cr_return_amount)
     FROM tpcds.catalog_returns cr2
     WHERE cr2.cr_item_sk = i.i_item_sk) AS avg_return_amount_for_item
FROM tpcds.catalog_page cp
JOIN tpcds.catalog_sales cs_raw
    ON cs_raw.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.item i
    ON cs_raw.cs_item_sk = i.i_item_sk
JOIN tpcds.catalog_returns cr
    ON cr.cr_order_number = cs_raw.cs_order_number
   AND cr.cr_item_sk = i.i_item_sk
JOIN tpcds.web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
JOIN tpcds.web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN sales_agg sa
    ON sa.cs_item_sk = i.i_item_sk
   AND sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE cp.cp_department = 'Sports'
  AND i.i_brand_id = 10005006
  AND cr.cr_return_amount > 50
  AND wp.wp_image_count >= 4
  AND EXISTS (
        SELECT 1
        FROM tpcds.catalog_returns cr3
        WHERE cr3.cr_order_number = cs_raw.cs_order_number
          AND cr3.cr_return_amount > 200
      )
ORDER BY cp.cp_catalog_page_id, i.i_item_id
