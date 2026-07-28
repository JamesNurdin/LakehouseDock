/*
Goal: Rank customers by total net loss from store returns that occurred during business hours, belong to higher‑income households, and have at least one web return. The query classifies income levels with a CASE expression and uses a window rank function.
*/
WITH customer_store_loss AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        ib.ib_upper_bound,
        SUM(sr.sr_net_loss) AS total_store_net_loss,
        COUNT(*) AS store_return_cnt,
        CASE
            WHEN ib.ib_upper_bound >= 150000 THEN 'High Income'
            WHEN ib.ib_upper_bound >= 100001 THEN 'Mid Income'
            ELSE 'Low Income'
        END AS income_category
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17                                          -- business hours
      AND ib.ib_upper_bound > 100000                                        -- higher‑income households
      AND sr.sr_return_quantity > 1                                         -- returns of more than one item
      AND EXISTS (                                                          -- semi‑join to web_returns
            SELECT 1
            FROM web_returns wr
            WHERE wr.wr_returning_customer_sk = c.c_customer_sk
              AND wr.wr_return_quantity > 0
        )
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        ib.ib_upper_bound
)
SELECT
    csl.c_customer_sk,
    csl.c_first_name,
    csl.c_last_name,
    csl.cd_gender,
    csl.income_category,
    csl.total_store_net_loss,
    csl.store_return_cnt,
    RANK() OVER (ORDER BY csl.total_store_net_loss DESC) AS loss_rank
FROM customer_store_loss csl
ORDER BY loss_rank
LIMIT 100
