WITH sampled_ws AS (
    SELECT *
    FROM tpcds.web_sales TABLESAMPLE BERNOULLI (10)
    WHERE ws_coupon_amt > 100
      AND ws_ext_wholesale_cost BETWEEN 500 AND 5000
      AND ws_quantity >= 2
      AND ws_ext_tax < 200
      AND ws_wholesale_cost > 0
      AND ws_ext_ship_cost > 0
),

combined AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        cd_bill.cd_gender AS bill_gender,
        cd_ship.cd_gender AS ship_gender,
        cd_bill.cd_credit_rating AS bill_credit_rating,
        cd_ship.cd_credit_rating AS ship_credit_rating,
        lr.discount_ratio
    FROM sampled_ws ws
    JOIN tpcds.customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN tpcds.customer_demographics cd_ship
        ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    LEFT JOIN LATERAL (
        SELECT (ws.ws_ext_discount_amt / NULLIF(ws.ws_ext_sales_price, 0)) AS discount_ratio
    ) lr ON true
    WHERE cd_bill.cd_dep_count >= 1
      AND cd_ship.cd_dep_count >= 1
      AND cd_bill.cd_credit_rating = 'Good'
      AND cd_ship.cd_credit_rating = 'Low Risk'
      AND ws.ws_net_profit > 0
      AND ws.ws_ext_sales_price > 100
),

ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY ws_net_profit DESC) AS global_row_num,
        RANK() OVER (PARTITION BY bill_credit_rating ORDER BY ws_net_profit DESC) AS credit_rank
    FROM combined
),

order_numbers_by_gender AS (
    SELECT ws_order_number
    FROM combined
    WHERE bill_gender = 'M' AND ship_gender = 'F'
),

order_numbers_by_credit AS (
    SELECT ws_order_number
    FROM combined
    WHERE bill_credit_rating = 'Good' AND ship_credit_rating = 'Low Risk'
),

intersected_orders AS (
    SELECT ws_order_number
    FROM order_numbers_by_gender
    INTERSECT
    SELECT ws_order_number
    FROM order_numbers_by_credit
)

SELECT
    r.ws_order_number,
    r.ws_sold_date_sk,
    r.ws_quantity,
    r.ws_ext_sales_price,
    r.ws_net_profit,
    r.bill_gender,
    r.ship_gender,
    r.bill_credit_rating,
    r.ship_credit_rating,
    r.discount_ratio,
    r.global_row_num,
    r.credit_rank
FROM ranked r
JOIN intersected_orders io ON r.ws_order_number = io.ws_order_number
ORDER BY r.global_row_num
LIMIT 100
