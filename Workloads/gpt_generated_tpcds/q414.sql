WITH store_sales_agg AS (
    SELECT ib.ib_lower_bound AS lower_bound,
           ib.ib_upper_bound AS upper_bound,
           ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN customer c
      ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
catalog_sales_agg AS (
    SELECT ib.ib_lower_bound AS lower_bound,
           ib.ib_upper_bound AS upper_bound,
           cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
web_sales_agg AS (
    SELECT ib.ib_lower_bound AS lower_bound,
           ib.ib_upper_bound AS upper_bound,
           ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN customer c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
      ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
all_sales AS (
    SELECT lower_bound, upper_bound, net_profit FROM store_sales_agg
    UNION ALL
    SELECT lower_bound, upper_bound, net_profit FROM catalog_sales_agg
    UNION ALL
    SELECT lower_bound, upper_bound, net_profit FROM web_sales_agg
)
SELECT lower_bound,
       upper_bound,
       SUM(net_profit) AS total_net_profit,
       COUNT(*) AS transaction_count,
       AVG(net_profit) AS avg_net_profit
FROM all_sales
WHERE lower_bound >= 40000
GROUP BY lower_bound, upper_bound
ORDER BY lower_bound
