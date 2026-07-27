WITH item_sales AS (
    SELECT
        i.i_item_sk,
        i.i_category_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_wholesale_cost > 10.00
    GROUP BY i.i_item_sk, i.i_category_id
)
SELECT
    d.d_year,
    w.w_warehouse_name,
    r.r_reason_desc,
    COUNT(DISTINCT cr.cr_order_number) AS num_catalog_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
    CASE WHEN SUM(cr.cr_return_amount) > 1000 THEN 'High' ELSE 'Low' END AS return_level,
    (
        SELECT AVG(isub.total_sales)
        FROM item_sales isub
        WHERE isub.i_category_id = i.i_category_id
    ) AS avg_category_sales
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                 AND inv.inv_warehouse_sk = w.w_warehouse_sk
                 AND inv.inv_date_sk = d.d_date_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
                  AND ws.ws_warehouse_sk = w.w_warehouse_sk
                  AND ws.ws_sold_date_sk = d.d_date_sk
WHERE w.w_state = 'CA'
  AND r.r_reason_desc IN ('Damaged', 'Defective')
  AND d.d_month_seq BETWEEN 1200 AND 1220
  AND i.i_category_id = 7
  AND inv.inv_quantity_on_hand > 0
  AND EXISTS (
        SELECT 1
        FROM web_returns wr
        JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
        WHERE wr.wr_item_sk = i.i_item_sk
          AND wp.wp_link_count > 15
          AND wr.wr_return_quantity > 0
    )
GROUP BY d.d_year, w.w_warehouse_name, r.r_reason_desc, i.i_category_id
HAVING SUM(cr.cr_return_amount) > 500
   AND COUNT(DISTINCT cr.cr_order_number) >= 5
ORDER BY total_net_profit DESC
LIMIT 100
