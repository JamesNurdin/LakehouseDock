WITH store AS (
    SELECT ib.ib_lower_bound,
           ib.ib_upper_bound,
           SUM(ss.ss_net_profit)               AS store_net_profit,
           SUM(ss.ss_ext_sales_price)          AS store_sales
    FROM store_sales ss
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
),
catalog AS (
    SELECT ib.ib_lower_bound,
           ib.ib_upper_bound,
           SUM(cs.cs_net_profit)               AS catalog_net_profit,
           SUM(cs.cs_ext_sales_price)          AS catalog_sales
    FROM catalog_sales cs
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
),
web AS (
    SELECT ib.ib_lower_bound,
           ib.ib_upper_bound,
           SUM(ws.ws_net_profit)               AS web_net_profit,
           SUM(ws.ws_ext_sales_price)          AS web_sales
    FROM web_sales ws
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
),
returns AS (
    SELECT ib.ib_lower_bound,
           ib.ib_upper_bound,
           SUM(cr.cr_net_loss)                 AS returns_net_loss,
           SUM(cr.cr_return_amount)            AS returns_amount
    FROM catalog_returns cr
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT COALESCE(s.ib_lower_bound, c.ib_lower_bound, w.ib_lower_bound, r.ib_lower_bound) AS lower_bound,
       COALESCE(s.ib_upper_bound, c.ib_upper_bound, w.ib_upper_bound, r.ib_upper_bound) AS upper_bound,
       COALESCE(s.store_net_profit, 0)    AS store_net_profit,
       COALESCE(c.catalog_net_profit, 0) AS catalog_net_profit,
       COALESCE(w.web_net_profit, 0)      AS web_net_profit,
       COALESCE(r.returns_net_loss, 0)    AS returns_net_loss,
       (COALESCE(s.store_net_profit, 0) + COALESCE(c.catalog_net_profit, 0) + COALESCE(w.web_net_profit, 0) - COALESCE(r.returns_net_loss, 0)) AS net_profit_after_returns
FROM   store   s
FULL   OUTER JOIN catalog c
       ON s.ib_lower_bound = c.ib_lower_bound AND s.ib_upper_bound = c.ib_upper_bound
FULL   OUTER JOIN web    w
       ON COALESCE(s.ib_lower_bound, c.ib_lower_bound) = w.ib_lower_bound
      AND COALESCE(s.ib_upper_bound, c.ib_upper_bound) = w.ib_upper_bound
FULL   OUTER JOIN returns r
       ON COALESCE(s.ib_lower_bound, c.ib_lower_bound, w.ib_lower_bound) = r.ib_lower_bound
      AND COALESCE(s.ib_upper_bound, c.ib_upper_bound, w.ib_upper_bound) = r.ib_upper_bound
WHERE  (COALESCE(s.store_net_profit, 0) + COALESCE(c.catalog_net_profit, 0) + COALESCE(w.web_net_profit, 0) - COALESCE(r.returns_net_loss, 0)) > 0
ORDER BY lower_bound, upper_bound
