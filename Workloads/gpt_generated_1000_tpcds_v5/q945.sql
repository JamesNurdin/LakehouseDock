WITH agg AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        i.i_brand AS brand,
        i.i_class AS class,
        sm.sm_carrier AS carrier,
        cp.cp_department AS department,
        wp.wp_type AS page_type,
        SUM(cr.cr_return_amount) AS catalog_return_amount,
        SUM(wr.wr_return_amt) AS web_return_amount,
        SUM(cr.cr_net_loss + wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS total_returns
    FROM catalog_returns cr
    JOIN date_dim d1
        ON cr.cr_returned_date_sk = d1.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
       AND wr.wr_returned_date_sk = d1.d_date_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d1.d_quarter_name = '1904Q4'
      AND sm.sm_carrier = 'AIRBORNE'
      AND i.i_class_id IN (14, 16)
      AND cp.cp_type IS NOT NULL
    GROUP BY
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_class,
        sm.sm_carrier,
        cp.cp_department,
        wp.wp_type
)
SELECT
    item_id,
    product_name,
    brand,
    class,
    carrier,
    department,
    page_type,
    catalog_return_amount,
    web_return_amount,
    total_net_loss,
    total_returns,
    RANK() OVER (PARTITION BY brand ORDER BY total_net_loss DESC) AS brand_net_loss_rank
FROM agg
ORDER BY total_net_loss DESC
LIMIT 100
