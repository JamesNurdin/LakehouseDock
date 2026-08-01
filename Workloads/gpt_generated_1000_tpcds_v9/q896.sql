WITH sales_by_category AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        i.i_category,
        d_sales.d_date,
        d_sales.d_year,
        SUM(ss.ss_net_profit) AS category_net_profit,
        SUM(ss.ss_ext_sales_price) AS category_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
       AND sr.sr_item_sk = ss.ss_item_sk
       AND sr.sr_store_sk = s.s_store_sk
       AND sr.sr_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN date_dim d_return
        ON sr.sr_returned_date_sk = d_return.d_date_sk
    LEFT JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    WHERE d_sales.d_year = 1998
      AND ib.ib_lower_bound > 20000
      AND hd.hd_vehicle_count >= 1
      AND NOT EXISTS (
            SELECT 1 FROM store_returns sr_ex
            WHERE sr_ex.sr_store_sk = s.s_store_sk
              AND sr_ex.sr_reason_sk = 5
        )
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        i.i_category,
        d_sales.d_date,
        d_sales.d_year
)
SELECT
    sbc.s_store_sk,
    sbc.s_store_name,
    sbc.i_category,
    sbc.category_net_profit,
    sbc.category_sales,
    sbc.num_transactions,
    SUM(sbc.category_net_profit) OVER (
        PARTITION BY sbc.s_store_sk 
        ORDER BY sbc.d_date 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_store_profit,
    AVG(sbc.category_net_profit) OVER (PARTITION BY sbc.s_store_sk) AS avg_category_profit,
    RANK() OVER (PARTITION BY sbc.s_store_sk ORDER BY sbc.category_net_profit DESC) AS profit_rank
FROM sales_by_category sbc
WHERE sbc.category_net_profit > (
    SELECT AVG(category_net_profit) FROM sales_by_category
)
ORDER BY sbc.s_store_sk, profit_rank
LIMIT 100
