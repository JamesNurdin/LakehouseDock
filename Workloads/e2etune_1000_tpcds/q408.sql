WITH city_sales AS (
    SELECT
        w.w_city,
        w.w_state,
        cd_bill.cd_credit_rating AS bill_credit_rating,
        cd_ship.cd_credit_rating AS ship_credit_rating,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders,
        SUM(ws.ws_net_paid) AS total_net_paid,
        AVG(ws.ws_net_paid) AS avg_net_paid,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM web_sales ws
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE cd_bill.cd_credit_rating = 'Good'
      AND cd_ship.cd_credit_rating = 'Good'
      AND cd_bill.cd_marital_status = 'M'
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2453650
    GROUP BY w.w_city, w.w_state, cd_bill.cd_credit_rating, cd_ship.cd_credit_rating
    HAVING COUNT(DISTINCT ws.ws_order_number) >= 100
)
SELECT
    cs.w_city,
    cs.w_state,
    cs.bill_credit_rating,
    cs.ship_credit_rating,
    cs.num_orders,
    cs.total_net_paid,
    cs.avg_net_paid,
    cs.total_discount,
    RANK() OVER (PARTITION BY cs.w_state ORDER BY cs.total_net_paid DESC) AS city_rank_in_state
FROM city_sales cs
ORDER BY cs.total_net_paid DESC
LIMIT 20
