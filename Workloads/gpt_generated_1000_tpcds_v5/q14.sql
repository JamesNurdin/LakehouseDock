WITH sales_high_profit AS (
    SELECT DISTINCT i.i_item_id,
           d.d_year AS year,
           'Sales' AS source
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_net_profit > 1000
      AND d.d_year BETWEEN 2000 AND 2002
),
returns_high_loss AS (
    SELECT DISTINCT i.i_item_id,
           d.d_year AS year,
           'Return' AS source
    FROM tpcds.web_returns wr
    JOIN tpcds.date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN tpcds.item i ON wr.wr_item_sk = i.i_item_sk
    WHERE wr.wr_net_loss > 500
      AND d.d_year BETWEEN 2000 AND 2002
)
SELECT i_item_id,
       year,
       source
FROM sales_high_profit
UNION
SELECT i_item_id,
       year,
       source
FROM returns_high_loss
ORDER BY i_item_id, year
LIMIT 100
