WITH store_sales_agg AS (
    SELECT
        d.d_year AS year,
        'Store' AS channel,
        i.i_item_id AS item_id,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND NOT EXISTS (
          SELECT 1
          FROM store_returns sr
          JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
          WHERE sr.sr_item_sk = ss.ss_item_sk
            AND dr.d_year = d.d_year
      )
    GROUP BY d.d_year, i.i_item_id
),
web_sales_agg AS (
    SELECT
        d.d_year AS year,
        'Web' AS channel,
        i.i_item_id AS item_id,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND NOT EXISTS (
          SELECT 1
          FROM web_returns wr
          JOIN date_dim dr ON wr.wr_returned_date_sk = dr.d_date_sk
          WHERE wr.wr_item_sk = ws.ws_item_sk
            AND dr.d_year = d.d_year
      )
    GROUP BY d.d_year, i.i_item_id
)
SELECT DISTINCT
    year,
    channel,
    item_id,
    total_net_paid,
    total_net_profit,
    CASE WHEN total_net_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_category
FROM (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
) AS combined
ORDER BY year, channel, total_net_paid DESC
LIMIT 100
