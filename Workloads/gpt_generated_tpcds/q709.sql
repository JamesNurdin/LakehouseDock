WITH store_sales_agg AS (
  SELECT
    d.d_year AS year,
    cd.cd_gender AS gender,
    SUM(ss.ss_net_profit) AS profit,
    CAST(0 AS decimal(7,2)) AS loss,
    CAST(0 AS integer) AS returns
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  WHERE d.d_date >= DATE '2000-01-01'
  GROUP BY d.d_year, cd.cd_gender
),
catalog_sales_agg AS (
  SELECT
    d.d_year AS year,
    cd.cd_gender AS gender,
    SUM(cs.cs_net_profit) AS profit,
    CAST(0 AS decimal(7,2)) AS loss,
    CAST(0 AS integer) AS returns
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  WHERE d.d_date >= DATE '2000-01-01'
  GROUP BY d.d_year, cd.cd_gender
),
web_sales_agg AS (
  SELECT
    d.d_year AS year,
    cd.cd_gender AS gender,
    SUM(ws.ws_net_profit) AS profit,
    CAST(0 AS decimal(7,2)) AS loss,
    CAST(0 AS integer) AS returns
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  WHERE d.d_date >= DATE '2000-01-01'
  GROUP BY d.d_year, cd.cd_gender
),
catalog_returns_agg AS (
  SELECT
    d.d_year AS year,
    cd.cd_gender AS gender,
    CAST(0 AS decimal(7,2)) AS profit,
    SUM(cr.cr_net_loss) AS loss,
    COUNT(*) AS returns
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
  WHERE d.d_date >= DATE '2000-01-01'
  GROUP BY d.d_year, cd.cd_gender
),
web_returns_agg AS (
  SELECT
    d.d_year AS year,
    cd.cd_gender AS gender,
    CAST(0 AS decimal(7,2)) AS profit,
    SUM(wr.wr_net_loss) AS loss,
    COUNT(*) AS returns
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
  WHERE d.d_date >= DATE '2000-01-01'
  GROUP BY d.d_year, cd.cd_gender
)
SELECT
  year,
  gender,
  SUM(profit) - SUM(loss) AS net_profit,
  SUM(returns) AS total_returns
FROM (
  SELECT * FROM store_sales_agg
  UNION ALL
  SELECT * FROM catalog_sales_agg
  UNION ALL
  SELECT * FROM web_sales_agg
  UNION ALL
  SELECT * FROM catalog_returns_agg
  UNION ALL
  SELECT * FROM web_returns_agg
) combined
GROUP BY year, gender
ORDER BY year, gender
