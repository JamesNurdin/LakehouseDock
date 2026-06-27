WITH
  sales_agg AS (
    SELECT
      cc.cc_call_center_sk AS cc_call_center_sk,
      cc.cc_name AS cc_name,
      d.d_year AS d_year,
      SUM(cs.cs_net_paid) AS total_net_paid,
      SUM(cs.cs_net_profit) AS total_net_profit,
      COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY cc.cc_call_center_sk, cc.cc_name, d.d_year
  ),
  returns_agg AS (
    SELECT
      cc.cc_call_center_sk AS cc_call_center_sk,
      cc.cc_name AS cc_name,
      d.d_year AS d_year,
      SUM(cr.cr_return_amount) AS total_return_amount,
      SUM(cr.cr_net_loss) AS total_return_net_loss,
      COUNT(*) AS returns_cnt
    FROM catalog_returns cr
    JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY cc.cc_call_center_sk, cc.cc_name, d.d_year
  )
SELECT
  s.cc_name,
  s.d_year,
  s.total_net_paid,
  s.total_net_profit,
  COALESCE(r.total_return_amount, 0) AS total_return_amount,
  COALESCE(r.total_return_net_loss, 0) AS total_return_net_loss,
  s.total_net_profit - COALESCE(r.total_return_net_loss, 0) AS net_profit_after_returns,
  s.sales_cnt,
  COALESCE(r.returns_cnt, 0) AS returns_cnt
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.cc_call_center_sk = r.cc_call_center_sk
  AND s.d_year = r.d_year
ORDER BY s.total_net_profit DESC
LIMIT 100
