WITH sales_join AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_quantity,
        cd.cd_gender,
        cd.cd_credit_rating,
        ts.t_hour,
        ts.t_meal_time
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim ts
        ON ss.ss_sold_time_sk = ts.t_time_sk
    WHERE cd.cd_gender = 'F'
      AND cd.cd_credit_rating IN ('Good', 'High Risk')
      AND ss.ss_quantity > 20
      AND ss.ss_ext_sales_price > 1000
),
returns_join AS (
    SELECT
        wr.wr_order_number,
        wr.wr_return_amt,
        wr.wr_fee,
        wr.wr_return_quantity,
        cd.cd_gender,
        cd.cd_credit_rating,
        tr.t_hour,
        tr.t_meal_time
    FROM web_returns wr
    JOIN customer_demographics cd
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim tr
        ON wr.wr_returned_time_sk = tr.t_time_sk
    WHERE cd.cd_gender = 'F'
      AND cd.cd_credit_rating IN ('Good', 'High Risk')
      AND wr.wr_return_quantity > 5
      AND wr.wr_return_amt > 200
)
SELECT
    s.cd_gender,
    s.t_hour,
    SUM(s.ss_ext_sales_price) AS total_sales_amount,
    SUM(r.wr_return_amt) AS total_return_amount,
    AVG(s.ss_net_profit) AS avg_net_profit,
    AVG(r.wr_fee) AS avg_return_fee,
    RANK() OVER (PARTITION BY s.cd_gender ORDER BY SUM(s.ss_ext_sales_price) DESC) AS sales_rank_by_hour,
    CASE
        WHEN AVG(s.ss_net_profit) > (SELECT AVG(ss_net_profit) FROM store_sales) THEN 'Above Avg Profit'
        ELSE 'Below Avg Profit'
    END AS profit_category
FROM sales_join s
LEFT JOIN returns_join r
    ON s.t_hour = r.t_hour
   AND s.cd_gender = r.cd_gender
GROUP BY s.cd_gender, s.t_hour
HAVING SUM(s.ss_ext_sales_price) > 5000
ORDER BY sales_rank_by_hour
LIMIT 100
