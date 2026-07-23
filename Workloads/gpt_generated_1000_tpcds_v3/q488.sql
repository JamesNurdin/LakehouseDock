WITH all_facts AS (
    SELECT
        cs_sold_date_sk AS date_sk,
        cs_item_sk AS item_sk,
        cs_warehouse_sk AS warehouse_sk,
        cs_call_center_sk AS call_center_sk,
        NULL AS store_sk,
        NULL AS reason_sk,
        NULL AS web_page_sk,
        cs_order_number AS order_number,
        cs_quantity AS quantity,
        cs_ext_sales_price AS sales_amount,
        NULL AS return_amount,
        cs_net_profit AS net_profit,
        NULL AS net_loss
    FROM catalog_sales

    UNION ALL

    SELECT
        cr_returned_date_sk AS date_sk,
        cr_item_sk AS item_sk,
        cr_warehouse_sk AS warehouse_sk,
        cr_call_center_sk AS call_center_sk,
        NULL AS store_sk,
        cr_reason_sk AS reason_sk,
        NULL AS web_page_sk,
        cr_order_number AS order_number,
        cr_return_quantity AS quantity,
        NULL AS sales_amount,
        cr_return_amount AS return_amount,
        NULL AS net_profit,
        cr_net_loss AS net_loss
    FROM catalog_returns

    UNION ALL

    SELECT
        sr_returned_date_sk AS date_sk,
        sr_item_sk AS item_sk,
        NULL AS warehouse_sk,
        NULL AS call_center_sk,
        sr_store_sk AS store_sk,
        sr_reason_sk AS reason_sk,
        NULL AS web_page_sk,
        NULL AS order_number,
        sr_return_quantity AS quantity,
        NULL AS sales_amount,
        sr_return_amt AS return_amount,
        NULL AS net_profit,
        sr_net_loss AS net_loss
    FROM store_returns

    UNION ALL

    SELECT
        ws_sold_date_sk AS date_sk,
        ws_item_sk AS item_sk,
        ws_warehouse_sk AS warehouse_sk,
        NULL AS call_center_sk,
        NULL AS store_sk,
        NULL AS reason_sk,
        ws_web_page_sk AS web_page_sk,
        ws_order_number AS order_number,
        ws_quantity AS quantity,
        ws_ext_sales_price AS sales_amount,
        NULL AS return_amount,
        ws_net_profit AS net_profit,
        NULL AS net_loss
    FROM web_sales

    UNION ALL

    SELECT
        wr_returned_date_sk AS date_sk,
        wr_item_sk AS item_sk,
        NULL AS warehouse_sk,
        NULL AS call_center_sk,
        NULL AS store_sk,
        wr_reason_sk AS reason_sk,
        wr_web_page_sk AS web_page_sk,
        wr_order_number AS order_number,
        wr_return_quantity AS quantity,
        NULL AS sales_amount,
        wr_return_amt AS return_amount,
        NULL AS net_profit,
        wr_net_loss AS net_loss
    FROM web_returns

    UNION ALL

    SELECT
        inv_date_sk AS date_sk,
        inv_item_sk AS item_sk,
        inv_warehouse_sk AS warehouse_sk,
        NULL AS call_center_sk,
        NULL AS store_sk,
        NULL AS reason_sk,
        NULL AS web_page_sk,
        NULL AS order_number,
        inv_quantity_on_hand AS quantity,
        NULL AS sales_amount,
        NULL AS return_amount,
        NULL AS net_profit,
        NULL AS net_loss
    FROM inventory
),
joined AS (
    SELECT
        d.d_year,
        i.i_category,
        w.w_city,
        cc.cc_name,
        s.s_state,
        r.r_reason_desc,
        wp.wp_type,
        SUM(COALESCE(f.sales_amount, 0)) AS total_sales,
        SUM(COALESCE(f.return_amount, 0)) AS total_returns,
        SUM(COALESCE(f.net_profit, 0)) AS total_profit,
        SUM(COALESCE(f.net_loss, 0)) AS total_loss,
        SUM(COALESCE(f.quantity, 0)) AS total_quantity,
        COUNT(*) AS transaction_count
    FROM all_facts f
    LEFT JOIN date_dim d ON f.date_sk = d.d_date_sk
    LEFT JOIN item i ON f.item_sk = i.i_item_sk
    LEFT JOIN warehouse w ON f.warehouse_sk = w.w_warehouse_sk
    LEFT JOIN call_center cc ON f.call_center_sk = cc.cc_call_center_sk
    LEFT JOIN store s ON f.store_sk = s.s_store_sk
    LEFT JOIN reason r ON f.reason_sk = r.r_reason_sk
    LEFT JOIN web_page wp ON f.web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand1'
      AND w.w_city = 'Los Angeles'
    GROUP BY d.d_year, i.i_category, w.w_city, cc.cc_name, s.s_state, r.r_reason_desc, wp.wp_type
)
SELECT
    d_year,
    i_category,
    w_city,
    cc_name,
    s_state,
    r_reason_desc,
    wp_type,
    total_sales,
    total_returns,
    total_profit,
    total_loss,
    transaction_count,
    total_sales / NULLIF(total_quantity, 0) AS avg_sales_per_quantity
FROM joined
WHERE total_sales > 10000
ORDER BY total_sales DESC
LIMIT 100
