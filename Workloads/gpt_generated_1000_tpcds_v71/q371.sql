WITH filtered_web_sales AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_net_paid_inc_tax
    FROM tpcds.web_sales ws
    WHERE ws.ws_net_paid_inc_tax > 1000
      AND NOT EXISTS (
          SELECT 1
          FROM tpcds.store_returns sr2
          WHERE sr2.sr_item_sk = ws.ws_item_sk
            AND sr2.sr_returned_date_sk = ws.ws_sold_date_sk
      )
)
SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_state,
    r.r_reason_desc,
    CASE WHEN ws.ws_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    AVG(sr.sr_net_loss) AS avg_net_loss,
    MIN(ws.ws_net_paid_inc_tax) AS min_paid_inc_tax,
    MAX(ws.ws_net_paid_inc_tax) AS max_paid_inc_tax
FROM filtered_web_sales ws
JOIN tpcds.date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN tpcds.date_dim d_ship
  ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN tpcds.inventory i
  ON i.inv_date_sk = d_sold.d_date_sk
JOIN tpcds.store_returns sr
  ON sr.sr_returned_date_sk = d_sold.d_date_sk
JOIN tpcds.store s
  ON s.s_store_sk = sr.sr_store_sk
JOIN tpcds.reason r
  ON r.r_reason_sk = sr.sr_reason_sk
JOIN tpcds.date_dim d_closed
  ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE d_sold.d_year = 2001
  AND s.s_state = 'CA'
  AND r.r_reason_desc = 'Customer Not Satisfied'
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_state,
    r.r_reason_desc,
    CASE WHEN ws.ws_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END
ORDER BY total_sales DESC
LIMIT 100
