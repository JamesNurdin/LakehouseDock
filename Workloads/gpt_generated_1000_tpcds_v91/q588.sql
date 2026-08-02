WITH order_without_return AS (
    SELECT ws.ws_order_number AS order_id
    FROM web_sales ws
    WHERE ws.ws_quantity >= 1
    EXCEPT
    SELECT wr.wr_order_number AS order_id
    FROM web_returns wr
    WHERE wr.wr_return_quantity > 0
),
base_data AS (
    SELECT
        cd.cd_gender AS cd_gender,
        cd.cd_credit_rating AS cd_credit_rating,
        ss.ss_quantity AS ss_quantity,
        ss.ss_ext_sales_price AS ss_ext_sales_price,
        p.p_promo_name AS p_promo_name,
        p.p_discount_active AS p_discount_active,
        p.p_cost AS p_cost,
        t.t_hour AS t_hour,
        ws.ws_order_number AS ws_order_number,
        ws.ws_quantity AS ws_quantity,
        ws.ws_ext_sales_price AS ws_ext_sales_price,
        ws.ws_net_paid AS ws_net_paid,
        ws.ws_net_profit AS ws_net_profit,
        wr.wr_return_quantity AS wr_return_quantity,
        wr.wr_return_amt AS wr_return_amt
    FROM customer_demographics cd
    JOIN store_sales ss
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = t.t_time_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    WHERE cd.cd_gender = 'F'
      AND p.p_discount_active = 'Y'
      AND t.t_hour = 10
      AND ss.ss_quantity >= 3
      AND ws.ws_quantity BETWEEN 1 AND 5
      AND ws.ws_order_number IN (SELECT order_id FROM order_without_return)
)
SELECT
    cd_gender,
    t_hour,
    p_promo_name,
    COUNT(DISTINCT ws_order_number) AS num_orders,
    SUM(ss_ext_sales_price) AS total_store_sales,
    SUM(ws_ext_sales_price) AS total_web_sales,
    SUM(COALESCE(lr.total_return_amt, 0)) AS total_return_amount,
    AVG(p_cost) AS avg_promo_cost,
    MIN(ss_ext_sales_price) AS min_store_sale,
    MAX(ss_ext_sales_price) AS max_store_sale
FROM base_data
LEFT JOIN LATERAL (
    SELECT SUM(wr2.wr_return_amt) AS total_return_amt
    FROM web_returns wr2
    WHERE wr2.wr_order_number = base_data.ws_order_number
) AS lr ON TRUE
GROUP BY cd_gender, t_hour, p_promo_name
ORDER BY total_store_sales DESC
LIMIT 100
