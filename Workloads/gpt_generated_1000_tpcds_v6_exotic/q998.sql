WITH joined_data AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sales_price,
        ss.ss_net_profit,
        t.t_hour,
        t.t_shift,
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cs.cs_ext_wholesale_cost,
        cs.cs_sales_price,
        cs.cs_net_profit
    FROM store_sales ss
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE ss.ss_sales_price > 20
      AND cs.cs_ext_wholesale_cost BETWEEN 1000 AND 8000
      AND hd.hd_dep_count >= 2
      AND ib.ib_upper_bound < 200000
      AND NOT EXISTS (
          SELECT 1 FROM catalog_sales cs2
          WHERE cs2.cs_order_number = ss.ss_ticket_number
      )
)
SELECT
    ss_ticket_number,
    ss_sales_price,
    cs_ext_wholesale_cost,
    hd_buy_potential,
    ib_lower_bound,
    ib_upper_bound,
    ROW_NUMBER() OVER (PARTITION BY ib_lower_bound ORDER BY ss_sales_price DESC) AS sales_rank,
    SUM(ss_net_profit) OVER (
        PARTITION BY hd_buy_potential
        ORDER BY ss_ticket_number
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_profit
FROM joined_data
ORDER BY sales_rank
LIMIT 100
