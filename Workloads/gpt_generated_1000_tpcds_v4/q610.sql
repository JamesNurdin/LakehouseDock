WITH filtered_data AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        d.d_year,
        w.w_warehouse_name,
        cr.cr_net_loss,
        ws.ws_net_profit,
        r.r_reason_desc,
        cp.cp_department,
        cd.cd_gender,
        inv.inv_quantity_on_hand
    FROM catalog_returns cr
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_demographics cd
      ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_returns wr
      ON wr.wr_order_number = cr.cr_order_number
     AND wr.wr_item_sk = cr.cr_item_sk
    LEFT JOIN web_sales ws
      ON ws.ws_order_number = cr.cr_order_number
     AND ws.ws_item_sk = cr.cr_item_sk
    LEFT JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
     AND inv.inv_warehouse_sk = w.w_warehouse_sk
     AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN web_page wp
      ON wp.wp_web_page_sk = ws.ws_web_page_sk
    WHERE d.d_year = 2001
      AND i.i_current_price BETWEEN 10 AND 100
      AND w.w_warehouse_sq_ft > 50000
      AND r.r_reason_id LIKE 'AAAAAAA%'
      AND cp.cp_department = 'Electronics'
      AND inv.inv_quantity_on_hand > 0
      AND EXISTS (
          SELECT 1 FROM web_sales ws2
          WHERE ws2.ws_item_sk = i.i_item_sk
            AND ws2.ws_sold_date_sk = d.d_date_sk
      )
)
SELECT
    d_year,
    i_item_id,
    i_product_name,
    w_warehouse_name,
    SUM(cr_net_loss) AS total_return_loss,
    SUM(ws_net_profit) AS total_sales_profit,
    CASE WHEN SUM(ws_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status,
    RANK() OVER (PARTITION BY d_year ORDER BY SUM(cr_net_loss) DESC) AS loss_rank
FROM filtered_data
GROUP BY d_year, i_item_id, i_product_name, w_warehouse_name
HAVING SUM(cr_net_loss) > 0
ORDER BY loss_rank
LIMIT 100
