WITH
  sales_agg AS (
    SELECT
      s.s_store_sk AS s_store_sk,
      d1.d_year AS year,
      SUM(cs.cs_net_profit) AS sales_profit,
      COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN date_dim d1 ON cs.cs_sold_date_sk = d1.d_date_sk
    JOIN household_demographics hd1 ON cs.cs_bill_hdemo_sk = hd1.hd_demo_sk
    JOIN store_returns sr ON sr.sr_hdemo_sk = hd1.hd_demo_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN web_site ws ON ws.web_open_date_sk = d1.d_date_sk
    WHERE d1.d_year = 2001
      AND hd1.hd_income_band_sk IN (10, 15, 20)
      AND ws.web_state = 'CA'
    GROUP BY s.s_store_sk, d1.d_year
  ),
  returns_agg AS (
    SELECT
      s.s_store_sk AS s_store_sk,
      d2.d_year AS year,
      SUM(sr.sr_net_loss) AS returns_loss,
      COUNT(*) AS returns_cnt
    FROM store_returns sr
    JOIN date_dim d2 ON sr.sr_returned_date_sk = d2.d_date_sk
    JOIN household_demographics hd2 ON sr.sr_hdemo_sk = hd2.hd_demo_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN web_site ws ON ws.web_open_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
      AND hd2.hd_income_band_sk IN (10, 15, 20)
      AND ws.web_state = 'CA'
    GROUP BY s.s_store_sk, d2.d_year
  ),
  combined AS (
    SELECT
      s_store_sk,
      year,
      sales_profit,
      0.0 AS returns_loss,
      sales_cnt AS trans_cnt
    FROM sales_agg
    UNION ALL
    SELECT
      s_store_sk,
      year,
      0.0 AS sales_profit,
      returns_loss,
      returns_cnt AS trans_cnt
    FROM returns_agg
  ),
  final_agg AS (
    SELECT
      s_store_sk,
      year,
      SUM(sales_profit) AS total_sales_profit,
      SUM(returns_loss) AS total_returns_loss,
      SUM(trans_cnt) AS total_transactions,
      (SUM(sales_profit) - SUM(returns_loss)) AS net_amount,
      AVG(SUM(sales_profit) - SUM(returns_loss)) OVER (PARTITION BY year) AS avg_net_amount_year
    FROM combined
    GROUP BY s_store_sk, year
  )
SELECT
  s_store_sk,
  year,
  total_sales_profit,
  total_returns_loss,
  net_amount,
  avg_net_amount_year,
  RANK() OVER (ORDER BY net_amount DESC) AS profit_rank
FROM final_agg
WHERE net_amount > (SELECT AVG(net_amount) FROM final_agg)
ORDER BY net_amount DESC
LIMIT 100
