WITH joined AS (
    SELECT
        cs.cs_order_number,
        cs.cs_bill_customer_sk,
        cs.cs_quantity,
        cs.cs_net_profit AS cs_net_profit,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        ss.ss_net_profit AS ss_net_profit,
        ws.ws_net_profit AS ws_net_profit,
        t1.t_hour,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        (cs.cs_net_profit + ss.ss_net_profit + ws.ws_net_profit) AS total_net_profit,
        CASE WHEN (cs.cs_net_profit + ss.ss_net_profit + ws.ws_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM catalog_sales cs
    JOIN time_dim t1
        ON cs.cs_sold_time_sk = t1.t_time_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    JOIN time_dim t2
        ON cr.cr_returned_time_sk = t2.t_time_sk
    JOIN store_sales ss
        ON ss.ss_sold_time_sk = t1.t_time_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = t1.t_time_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cs.cs_quantity > 5
      AND cr.cr_return_amount > 1000
      AND ss.ss_net_profit > 0
      AND ws.ws_net_profit < 5000
      AND ib.ib_upper_bound >= 50000
      AND t1.t_hour BETWEEN 9 AND 17
      AND NOT EXISTS (
          SELECT 1 FROM catalog_returns crx
          WHERE crx.cr_order_number = ws.ws_order_number
      )
)
SELECT
    profit_category,
    SUM(total_net_profit) AS category_profit,
    COUNT(*) AS orders_cnt,
    CASE WHEN SUM(total_net_profit) > 20000 THEN 'Very High' ELSE 'Normal' END AS category_label,
    RANK() OVER (ORDER BY SUM(total_net_profit) DESC) AS profit_rank,
    SUM(SUM(total_net_profit)) OVER (ORDER BY SUM(total_net_profit) DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_category_profit
FROM joined
GROUP BY profit_category
HAVING SUM(total_net_profit) > 1000
ORDER BY profit_rank
LIMIT 100
