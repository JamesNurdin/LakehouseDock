SELECT
    wr.wr_order_number,
    r.r_reason_desc,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    ws.ws_quantity,
    ws.ws_sales_price,
    (ws.ws_sales_price * ws.ws_quantity) AS sales_total,
    (ws.ws_sales_price * ws.ws_quantity) - wr.wr_return_amt AS discrepancy,
    CASE
        WHEN (ws.ws_sales_price * ws.ws_quantity) - wr.wr_return_amt > 0 THEN 'OVER_CHARGE'
        WHEN (ws.ws_sales_price * ws.ws_quantity) - wr.wr_return_amt < 0 THEN 'UNDER_CHARGE'
        ELSE 'BALANCED'
    END AS discrepancy_type,
    RANK() OVER (ORDER BY ABS((ws.ws_sales_price * ws.ws_quantity) - wr.wr_return_amt) DESC) AS discrepancy_rank
FROM web_returns wr
JOIN web_sales ws
    ON wr.wr_item_sk = ws.ws_item_sk
   AND wr.wr_order_number = ws.ws_order_number
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
WHERE wr.wr_return_quantity > 0
ORDER BY discrepancy_rank
LIMIT 10
