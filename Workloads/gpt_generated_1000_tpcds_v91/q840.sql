WITH base_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_ext_discount_amt,
        cs.cs_ext_ship_cost,
        cs.cs_coupon_amt,
        cs.cs_sales_price,
        s.s_city,
        s.s_store_name,
        td.t_hour,
        td.t_minute,
        td.t_second,
        r.r_reason_desc,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss
    FROM catalog_sales cs
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN store_returns sr
        ON sr.sr_return_time_sk = td.t_time_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE cs.cs_ext_ship_cost > 500
      AND cs.cs_coupon_amt < 1000
      AND cs.cs_sales_price BETWEEN 5 AND 200
      AND td.t_hour BETWEEN 8 AND 20
      AND s.s_city IN ('Springfield', 'Fairview', 'Riverside')
      AND r.r_reason_desc NOT LIKE '%defective%'
),

rollup_agg AS (
    SELECT
        s_city,
        t_hour,
        SUM(cs_ext_sales_price) AS sum_sales_price,
        SUM(cs_net_profit) AS sum_net_profit,
        SUM(sr_net_loss) AS sum_net_loss,
        COUNT(DISTINCT cs_order_number) AS order_cnt
    FROM base_data
    GROUP BY ROLLUP(s_city, t_hour)
),

windowed_agg AS (
    SELECT
        s_city,
        t_hour,
        sum_sales_price,
        sum_net_profit,
        sum_net_loss,
        order_cnt,
        RANK() OVER (ORDER BY sum_net_profit DESC) AS profit_rank,
        SUM(sum_net_profit) OVER (
            PARTITION BY s_city
            ORDER BY t_hour
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_city_profit
    FROM rollup_agg
)

SELECT
    s_city,
    t_hour,
    sum_sales_price,
    sum_net_profit,
    sum_net_loss,
    order_cnt,
    profit_rank,
    cumulative_city_profit,
    (
        SELECT MAX(bd2.cs_ext_sales_price)
        FROM base_data bd2
        WHERE bd2.s_city = wa.s_city
    ) AS metric_value
FROM windowed_agg wa
WHERE s_city IS NOT NULL

UNION ALL

SELECT
    s_city,
    t_hour,
    sum_sales_price,
    sum_net_profit,
    sum_net_loss,
    order_cnt,
    profit_rank,
    cumulative_city_profit,
    (
        SELECT AVG(bd3.cs_net_profit)
        FROM base_data bd3
    ) AS metric_value
FROM windowed_agg wa2
WHERE s_city IS NULL

ORDER BY sum_net_profit DESC
LIMIT 100
