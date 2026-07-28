WITH joined_data AS (
    SELECT
        i1.i_class,
        cc1.cc_name,
        cp1.cp_type,
        ss.ss_ext_sales_price AS store_sales_amount,
        ws.ws_ext_sales_price AS web_sales_amount,
        cr.cr_return_amount AS return_amount,
        cr.cr_net_loss AS net_loss
    FROM store_sales ss
    JOIN item i1 ON ss.ss_item_sk = i1.i_item_sk                         -- join 1
    JOIN item i4 ON ss.ss_item_sk = i4.i_item_sk                         -- join 2 (second alias of item)
    JOIN catalog_returns cr ON cr.cr_item_sk = i1.i_item_sk               -- join 3
    JOIN item i3 ON cr.cr_item_sk = i3.i_item_sk                         -- join 4 (second alias for returns)
    JOIN call_center cc1 ON cr.cr_call_center_sk = cc1.cc_call_center_sk -- join 5
    JOIN call_center cc2 ON cr.cr_call_center_sk = cc2.cc_call_center_sk -- join 6 (second alias of call_center)
    JOIN catalog_page cp1 ON cr.cr_catalog_page_sk = cp1.cp_catalog_page_sk -- join 7
    JOIN catalog_page cp2 ON cr.cr_catalog_page_sk = cp2.cp_catalog_page_sk -- join 8 (second alias of catalog_page)
    JOIN web_sales ws ON ws.ws_item_sk = i1.i_item_sk                    -- join 9
    JOIN item i2 ON ws.ws_item_sk = i2.i_item_sk                         -- join 10 (second alias for web_sales)
    WHERE EXISTS (
        SELECT 1
        FROM catalog_page cp_sub
        WHERE cp_sub.cp_catalog_number = 15
          AND cp_sub.cp_catalog_page_sk = cp1.cp_catalog_page_sk
    )
      AND i1.i_class_id IN (7, 13)
)
SELECT
    i_class,
    cc_name,
    cp_type,
    SUM(store_sales_amount) AS total_store_sales,
    SUM(web_sales_amount)   AS total_web_sales,
    SUM(return_amount)      AS total_returns,
    SUM(net_loss)           AS total_net_loss,
    SUM(store_sales_amount + web_sales_amount - return_amount - net_loss) AS net_revenue,
    RANK() OVER (ORDER BY SUM(store_sales_amount + web_sales_amount - return_amount - net_loss) DESC) AS revenue_rank
FROM joined_data
GROUP BY i_class, cc_name, cp_type
ORDER BY net_revenue DESC
LIMIT 100
