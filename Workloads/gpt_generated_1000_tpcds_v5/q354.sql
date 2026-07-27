WITH base AS (
    SELECT
        d.d_date,
        d.d_year,
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        r.r_reason_desc,
        cs.cs_net_paid,
        cs.cs_ext_sales_price,
        sr.sr_net_loss,
        inv.inv_quantity_on_hand,
        cp.cp_catalog_number,
        wp.wp_url,
        wr.wr_return_amt
    FROM tpcds.date_dim d
    JOIN tpcds.store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN tpcds.item i ON sr.sr_item_sk = i.i_item_sk
    JOIN tpcds.reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN tpcds.inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_item_sk = i.i_item_sk
    JOIN tpcds.catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk AND cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN tpcds.web_returns wr ON wr.wr_web_page_sk = wp.wp_web_page_sk
                              AND wr.wr_returned_date_sk = d.d_date_sk
                              AND wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
      AND r.r_reason_desc LIKE '%damaged%'
      AND inv.inv_quantity_on_hand > 0
      AND cp.cp_catalog_number > 50
      AND EXISTS (
          SELECT 1 FROM tpcds.web_returns wr2
          WHERE wr2.wr_item_sk = i.i_item_sk AND wr2.wr_return_amt > 100
      )
)
SELECT
    i_item_id,
    i_product_name,
    d_date,
    cs_net_paid,
    sr_net_loss,
    CASE WHEN sr_net_loss > 0 THEN 'Loss' ELSE 'Gain' END AS loss_indicator,
    (SELECT AVG(cs2.cs_ext_sales_price)
       FROM tpcds.catalog_sales cs2
       WHERE cs2.cs_item_sk = base.i_item_sk) AS avg_item_sales_price,
    ROW_NUMBER() OVER (PARTITION BY i_item_id ORDER BY cs_net_paid DESC) AS sales_rank
FROM base
ORDER BY sales_rank ASC, d_date DESC
LIMIT 100
