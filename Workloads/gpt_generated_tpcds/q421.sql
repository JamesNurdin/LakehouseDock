WITH sales_agg AS (
    SELECT
        cs.cs_call_center_sk AS call_center_sk,
        d.d_year,
        d.d_moy,
        SUM(cs.cs_net_profit) AS total_sales_profit
    FROM catalog_sales cs
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY cs.cs_call_center_sk, d.d_year, d.d_moy
),
returns_agg AS (
    SELECT
        cr.cr_call_center_sk AS call_center_sk,
        d.d_year,
        d.d_moy,
        SUM(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY cr.cr_call_center_sk, d.d_year, d.d_moy
)
SELECT
    cc.cc_name                     AS call_center_name,
    s.d_year,
    s.d_moy                        AS month_of_year,
    s.total_sales_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_sales_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.call_center_sk = r.call_center_sk
  AND s.d_year = r.d_year
  AND s.d_moy = r.d_moy
JOIN call_center cc
  ON s.call_center_sk = cc.cc_call_center_sk
WHERE s.d_year IN (2001, 2002)
ORDER BY net_profit_after_returns DESC
LIMIT 10
