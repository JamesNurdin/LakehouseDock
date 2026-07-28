WITH filtered_sales AS (
    SELECT
        ws.ws_sold_time_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_ship_cdemo_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_discount_amt,
        ws.ws_ext_list_price,
        ws.ws_net_profit,
        t.t_sub_shift,
        cd_b.cd_gender,
        cd_b.cd_education_status,
        cd_b.cd_dep_count
    FROM web_sales ws
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd_b
        ON ws.ws_bill_cdemo_sk = cd_b.cd_demo_sk
    WHERE ws.ws_ext_discount_amt > 1000                       -- predicate 1
      AND ws.ws_quantity >= 2                                 -- predicate 2
      AND cd_b.cd_dep_count <= 4                              -- predicate 3
      AND t.t_sub_shift IN ('morning','afternoon','evening')  -- predicate 4
      AND ws.ws_ext_list_price < 8000                         -- predicate 5
      AND NOT EXISTS (
            SELECT 1
            FROM web_sales ws2
            JOIN customer_demographics cd_s
                 ON ws2.ws_ship_cdemo_sk = cd_s.cd_demo_sk
            WHERE ws2.ws_order_number = ws.ws_order_number
              AND cd_s.cd_dep_employed_count > 5
        )
),
aggregated AS (
    SELECT
        t_sub_shift,
        cd_gender,
        cd_education_status,
        SUM(ws_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        AVG(ws_ext_discount_amt) AS avg_discount
    FROM filtered_sales
    GROUP BY t_sub_shift, cd_gender, cd_education_status
)
SELECT
    t_sub_shift,
    cd_gender,
    cd_education_status,
    total_profit,
    sales_cnt,
    avg_discount,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank,
    SUM(total_profit) OVER (
        PARTITION BY cd_gender
        ORDER BY total_profit
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cum_profit_by_gender
FROM aggregated
ORDER BY profit_rank
LIMIT 100
