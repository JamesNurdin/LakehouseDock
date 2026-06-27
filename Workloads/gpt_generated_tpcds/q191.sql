WITH store_sales_agg AS (
  SELECT
    i.i_brand AS brand,
    cd.cd_gender AS gender,
    d.d_year AS sales_year,
    'store' AS channel,
    SUM(ss.ss_net_profit) AS net_profit
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 1998 AND 2000
  GROUP BY i.i_brand, cd.cd_gender, d.d_year
),
web_sales_agg AS (
  SELECT
    i.i_brand AS brand,
    cd.cd_gender AS gender,
    d.d_year AS sales_year,
    'web' AS channel,
    SUM(ws.ws_net_profit) AS net_profit
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 1998 AND 2000
  GROUP BY i.i_brand, cd.cd_gender, d.d_year
),
web_returns_agg AS (
  SELECT
    i.i_brand AS brand,
    cd.cd_gender AS gender,
    d.d_year AS sales_year,
    SUM(wr.wr_net_loss) AS net_loss
  FROM web_returns wr
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 1998 AND 2000
  GROUP BY i.i_brand, cd.cd_gender, d.d_year
)

SELECT
  s.brand,
  s.gender,
  s.sales_year,
  s.channel,
  (s.net_profit - COALESCE(r.net_loss, 0)) AS net_profit_after_returns
FROM (
  SELECT brand, gender, sales_year, channel, net_profit FROM store_sales_agg
  UNION ALL
  SELECT brand, gender, sales_year, channel, net_profit FROM web_sales_agg
) s
LEFT JOIN web_returns_agg r
  ON s.brand = r.brand
  AND s.gender = r.gender
  AND s.sales_year = r.sales_year
ORDER BY s.brand, s.gender, s.sales_year, s.channel
