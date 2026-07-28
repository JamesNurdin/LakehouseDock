WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        i.i_category,
        i.i_item_desc,
        i.i_item_id,
        c.c_current_hdemo_sk,
        hd.hd_income_band_sk,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE regexp_like(i.i_item_desc, '(?i)bright')
      AND i.i_item_id LIKE '00%'
      AND ss.ss_net_paid > 0
)
SELECT
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    i_category,
    SUM(ss_quantity) AS total_quantity,
    SUM(ss_net_paid) AS total_net_paid,
    AVG(ss_net_profit) AS avg_net_profit,
    CASE
        WHEN AVG(ss_net_profit) > (SELECT AVG(ss_net_profit) FROM store_sales) THEN 'Above Avg Profit'
        ELSE 'Below Avg Profit'
    END AS profit_category,
    RANK() OVER (PARTITION BY ib_income_band_sk ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
FROM filtered_sales
GROUP BY ib_income_band_sk, ib_lower_bound, ib_upper_bound, i_category
HAVING SUM(ss_net_paid) > 10000
ORDER BY ib_income_band_sk, sales_rank
LIMIT 100
