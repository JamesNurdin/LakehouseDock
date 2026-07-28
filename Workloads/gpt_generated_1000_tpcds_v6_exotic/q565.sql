WITH cs_ws AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_state,
        t.t_meal_time,
        hd.hd_dep_count,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        ws.ws_ext_sales_price,
        ws.ws_net_profit
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = t.t_time_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE t.t_meal_time = 'lunch'
      AND hd.hd_dep_count >= 2
      AND cc.cc_state = 'TX'
      AND cs.cs_ext_sales_price > 1000
)
SELECT
    cc_name,
    cc_state,
    t_meal_time,
    SUM(cs_ext_sales_price) AS total_catalog_sales,
    SUM(ws_ext_sales_price) AS total_web_sales,
    SUM(cs_net_profit + ws_net_profit) AS total_profit,
    RANK() OVER (ORDER BY SUM(cs_net_profit + ws_net_profit) DESC) AS profit_rank,
    (
        SELECT AVG(cs_ext_sales_price + ws_ext_sales_price)
        FROM cs_ws
    ) AS avg_total_sales_per_row
FROM cs_ws
GROUP BY cc_name, cc_state, t_meal_time
HAVING SUM(cs_ext_sales_price) > 2000
ORDER BY total_profit DESC
LIMIT 100
