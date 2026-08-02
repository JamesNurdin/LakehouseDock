WITH base AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_net_loss,
        wr.wr_item_sk,
        wr.wr_order_number,
        wr.wr_reason_sk,
        ws.ws_ext_sales_price,
        ws.ws_wholesale_cost,
        ws.ws_quantity,
        r.r_reason_id,
        r.r_reason_desc
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_item_sk = ws.ws_item_sk
       AND wr.wr_order_number = ws.ws_order_number
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_return_tax > 20.00
      AND wr.wr_net_loss BETWEEN 500 AND 5000
      AND ws.ws_ext_sales_price > 500.00
      AND ws.ws_wholesale_cost < 70.00
      AND r.r_reason_id LIKE 'AAAAAAA%'
      AND ws.ws_quantity > 0
      AND NOT EXISTS (
          SELECT 1
          FROM web_sales ws2
          WHERE ws2.ws_order_number = wr.wr_order_number
            AND ws2.ws_quantity > 100
      )
      AND wr.wr_net_loss > (
          SELECT AVG(wr3.wr_net_loss)
          FROM web_returns wr3
          WHERE wr3.wr_reason_sk = wr.wr_reason_sk
      )
)

SELECT
    b.wr_returned_date_sk,
    b.wr_order_number,
    b.r_reason_id,
    b.wr_net_loss,
    CASE WHEN b.wr_net_loss > 2000 THEN 'High' ELSE 'Medium' END AS loss_category,
    RANK() OVER (PARTITION BY b.r_reason_id ORDER BY b.wr_net_loss DESC) AS net_loss_rank
FROM base b
WHERE b.wr_return_quantity >= 2

UNION DISTINCT

SELECT
    b.wr_returned_date_sk,
    b.wr_order_number,
    b.r_reason_id,
    b.wr_net_loss,
    CASE WHEN b.wr_net_loss > 2000 THEN 'High' ELSE 'Medium' END AS loss_category,
    RANK() OVER (PARTITION BY b.r_reason_id ORDER BY b.wr_net_loss DESC) AS net_loss_rank
FROM base b
WHERE b.ws_quantity >= 2

ORDER BY net_loss_rank, wr_returned_date_sk
LIMIT 100
