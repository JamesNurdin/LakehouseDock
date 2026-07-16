WITH sales AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count,
        SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451910 AND 2451915
      AND ws.ws_ship_mode_sk IN (1, 2, 3)
    GROUP BY cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
returns AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_count
    FROM web_returns wr
    JOIN customer_demographics cd
        ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2451910 AND 2451915
    GROUP BY cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
)
SELECT
    s.cd_gender,
    s.cd_marital_status,
    s.cd_credit_rating,
    s.total_sales,
    s.total_profit,
    s.orders_count,
    s.total_quantity,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.return_count, 0) AS return_count,
    CASE WHEN s.total_sales > 0 THEN COALESCE(r.total_return_amount, 0) / s.total_sales ELSE 0 END AS return_rate,
    RANK() OVER (ORDER BY s.total_profit DESC) AS profit_rank
FROM sales s
LEFT JOIN returns r
    ON s.cd_gender = r.cd_gender
   AND s.cd_marital_status = r.cd_marital_status
   AND s.cd_credit_rating = r.cd_credit_rating
ORDER BY s.total_profit DESC
LIMIT 100
