WITH store_sales_filtered AS (
    SELECT
        d.d_date AS sale_date,
        'store' AS channel,
        i.i_item_id AS item_id,
        ss.ss_ext_sales_price AS sales_amount,
        ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND ss.ss_net_profit > 0
      AND NOT EXISTS (
          SELECT 1 FROM store_returns sr
          WHERE sr.sr_ticket_number = ss.ss_ticket_number
      )
),
web_sales_filtered AS (
    SELECT
        d.d_date AS sale_date,
        'web' AS channel,
        i.i_item_id AS item_id,
        ws.ws_ext_sales_price AS sales_amount,
        ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND ws.ws_net_profit > 0
      AND NOT EXISTS (
          SELECT 1 FROM web_returns wr
          WHERE wr.wr_order_number = ws.ws_order_number
      )
)
SELECT *
FROM store_sales_filtered
UNION ALL
SELECT *
FROM web_sales_filtered
ORDER BY sale_date DESC, channel
LIMIT 100
