WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_net_paid,
        cs.cs_catalog_page_sk,
        cs.cs_warehouse_sk
    FROM catalog_sales cs
    WHERE cs.cs_quantity >= 5
      AND cs.cs_net_paid > 100
)
SELECT
    cp.cp_catalog_page_id,
    w.w_warehouse_name,
    td.t_hour,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(DISTINCT cs.cs_order_number) AS order_count,
    SUM(COALESCE(cr.cr_return_amount, 0)) AS total_return_amount,
    SUM(COALESCE(cr.cr_return_quantity, 0)) AS total_return_quantity,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_web_return_amount,
    SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_web_return_quantity
FROM filtered_sales cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN time_dim td
    ON cs.cs_sold_time_sk = td.t_time_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
    AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    AND cr.cr_warehouse_sk = w.w_warehouse_sk
    AND cr.cr_return_quantity > 0
LEFT JOIN web_returns wr
    ON wr.wr_returned_time_sk = td.t_time_sk
    AND wr.wr_fee > 20
WHERE cp.cp_type = 'monthly'
  AND cp.cp_catalog_number IN (1, 6, 9)
  AND w.w_state = 'CA'
  AND td.t_minute IN (1, 4, 8)
GROUP BY cp.cp_catalog_page_id, w.w_warehouse_name, td.t_hour
ORDER BY total_sales DESC
