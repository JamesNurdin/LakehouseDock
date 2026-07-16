WITH catalog AS (
    SELECT ib.ib_lower_bound,
           ib.ib_upper_bound,
           cs.cs_net_profit,
           cs.cs_quantity,
           cs.cs_ext_discount_amt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_fy_year = 2001 AND d.d_fy_quarter_seq = 1
),
store AS (
    SELECT ib.ib_lower_bound,
           ib.ib_upper_bound,
           ss.ss_net_profit,
           ss.ss_quantity,
           ss.ss_ext_discount_amt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_fy_year = 2001 AND d.d_fy_quarter_seq = 1
),
returns AS (
    SELECT ib.ib_lower_bound,
           ib.ib_upper_bound,
           wr.wr_net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_fy_year = 2001 AND d.d_fy_quarter_seq = 1
)
SELECT ib_lower_bound,
       ib_upper_bound,
       SUM(net_profit) AS total_net_profit,
       SUM(quantity) AS total_quantity,
       AVG(NULLIF(discount_amt, 0)) AS avg_discount_amt,
       RANK() OVER (ORDER BY SUM(net_profit) DESC) AS profit_rank
FROM (
    SELECT ib_lower_bound,
           ib_upper_bound,
           cs_net_profit AS net_profit,
           cs_quantity AS quantity,
           cs_ext_discount_amt AS discount_amt
    FROM catalog
    UNION ALL
    SELECT ib_lower_bound,
           ib_upper_bound,
           ss_net_profit AS net_profit,
           ss_quantity AS quantity,
           ss_ext_discount_amt AS discount_amt
    FROM store
    UNION ALL
    SELECT ib_lower_bound,
           ib_upper_bound,
           -wr_net_loss AS net_profit,
           0 AS quantity,
           0 AS discount_amt
    FROM returns
) t
GROUP BY ib_lower_bound, ib_upper_bound
HAVING SUM(net_profit) > 0
ORDER BY profit_rank
LIMIT 10
