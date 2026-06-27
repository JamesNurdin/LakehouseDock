/*
   Monthly net profit analysis for the year 2000.
   Combines catalog sales, web sales and web returns.
   Net profit after returns = catalog profit + web profit – returns loss.
*/
WITH catalog_monthly AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_net_profit)               AS catalog_net_profit,
        SUM(cs.cs_ext_discount_amt)         AS catalog_discount
    FROM catalog_sales cs
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2000-01-01'
      AND d.d_date < DATE '2001-01-01'
    GROUP BY d.d_year, d.d_month_seq
),
web_monthly AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_net_profit)               AS web_net_profit,
        SUM(ws.ws_ext_discount_amt)         AS web_discount
    FROM web_sales ws
    JOIN date_dim d
      ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2000-01-01'
      AND d.d_date < DATE '2001-01-01'
    GROUP BY d.d_year, d.d_month_seq
),
returns_monthly AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(wr.wr_net_loss)                 AS returns_net_loss
    FROM web_returns wr
    JOIN date_dim d
      ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2000-01-01'
      AND d.d_date < DATE '2001-01-01'
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    COALESCE(cm.d_year, wm.d_year, rm.d_year)            AS year,
    COALESCE(cm.d_month_seq, wm.d_month_seq, rm.d_month_seq) AS month_seq,
    COALESCE(cm.catalog_net_profit, 0) +
    COALESCE(wm.web_net_profit, 0) -
    COALESCE(rm.returns_net_loss, 0)                     AS net_profit_after_returns,
    COALESCE(cm.catalog_discount, 0) +
    COALESCE(wm.web_discount, 0)                         AS total_discount_amount
FROM catalog_monthly cm
FULL OUTER JOIN web_monthly wm
  ON cm.d_year = wm.d_year AND cm.d_month_seq = wm.d_month_seq
FULL OUTER JOIN returns_monthly rm
  ON COALESCE(cm.d_year, wm.d_year) = rm.d_year
 AND COALESCE(cm.d_month_seq, wm.d_month_seq) = rm.d_month_seq
ORDER BY year, month_seq
