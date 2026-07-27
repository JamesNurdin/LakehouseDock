WITH base AS (
    SELECT
        cp.cp_description AS cp_description,
        hd.hd_buy_potential AS hd_buy_potential,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(wr.wr_return_amt) AS total_web_return_amt,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN web_returns wr
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE cp.cp_type = 'A'
      AND cp.cp_description LIKE '%store%'
      AND cr.cr_ship_mode_sk IN (5, 9)
      AND wr.wr_web_page_sk = 589
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY cp.cp_description, hd.hd_buy_potential
)
SELECT
    cp_description,
    hd_buy_potential,
    total_profit,
    total_return_amount,
    total_web_return_amt,
    order_cnt,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM base
ORDER BY profit_rank
LIMIT 100
