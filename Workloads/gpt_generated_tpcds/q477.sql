WITH store_sales_agg AS (
    SELECT ib.ib_lower_bound,
           ib.ib_upper_bound,
           SUM(ss.ss_net_profit) AS profit
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
),
catalog_sales_agg AS (
    SELECT ib.ib_lower_bound,
           ib.ib_upper_bound,
           SUM(cs.cs_net_profit) AS profit
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
),
web_sales_agg AS (
    SELECT ib.ib_lower_bound,
           ib.ib_upper_bound,
           SUM(ws.ws_net_profit) AS profit
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
),
store_returns_agg AS (
    SELECT ib.ib_lower_bound,
           ib.ib_upper_bound,
           SUM(sr.sr_net_loss) AS loss
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
),
catalog_returns_agg AS (
    SELECT ib.ib_lower_bound,
           ib.ib_upper_bound,
           SUM(cr.cr_net_loss) AS loss
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
),
web_returns_agg AS (
    SELECT ib.ib_lower_bound,
           ib.ib_upper_bound,
           SUM(wr.wr_net_loss) AS loss
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
),
sales_agg AS (
    SELECT ib_lower_bound,
           ib_upper_bound,
           SUM(profit) AS total_profit
    FROM (
        SELECT ib_lower_bound, ib_upper_bound, profit FROM store_sales_agg
        UNION ALL
        SELECT ib_lower_bound, ib_upper_bound, profit FROM catalog_sales_agg
        UNION ALL
        SELECT ib_lower_bound, ib_upper_bound, profit FROM web_sales_agg
    ) t
    GROUP BY ib_lower_bound, ib_upper_bound
),
returns_agg AS (
    SELECT ib_lower_bound,
           ib_upper_bound,
           SUM(loss) AS total_loss
    FROM (
        SELECT ib_lower_bound, ib_upper_bound, loss FROM store_returns_agg
        UNION ALL
        SELECT ib_lower_bound, ib_upper_bound, loss FROM catalog_returns_agg
        UNION ALL
        SELECT ib_lower_bound, ib_upper_bound, loss FROM web_returns_agg
    ) t
    GROUP BY ib_lower_bound, ib_upper_bound
)
SELECT s.ib_lower_bound,
       s.ib_upper_bound,
       s.total_profit,
       COALESCE(r.total_loss, 0) AS total_loss,
       s.total_profit - COALESCE(r.total_loss, 0) AS net_contribution
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.ib_lower_bound = r.ib_lower_bound
 AND s.ib_upper_bound = r.ib_upper_bound
ORDER BY net_contribution DESC
LIMIT 10
