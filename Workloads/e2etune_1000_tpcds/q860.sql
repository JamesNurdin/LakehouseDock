WITH per_warehouse AS (
    SELECT
        w.w_state AS state,
        cd_bill.cd_credit_rating AS credit_rating,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
        SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship
        ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE cd_bill.cd_purchase_estimate >= 1500
      AND cd_bill.cd_marital_status = 'M'
      AND cd_ship.cd_gender = 'F'
    GROUP BY w.w_state, cd_bill.cd_credit_rating
),
overall_avg AS (
    SELECT
        credit_rating,
        AVG(total_net_profit) AS overall_avg_profit
    FROM per_warehouse
    GROUP BY credit_rating
)
SELECT
    pw.state,
    pw.credit_rating,
    pw.total_net_profit,
    pw.avg_discount,
    pw.distinct_customers,
    pw.total_quantity,
    pw.total_net_profit / oa.overall_avg_profit AS profit_to_avg_ratio,
    ROW_NUMBER() OVER (PARTITION BY pw.credit_rating ORDER BY pw.total_net_profit DESC) AS profit_rank
FROM per_warehouse pw
JOIN overall_avg oa
    ON pw.credit_rating = oa.credit_rating
WHERE pw.total_net_profit > 10000
ORDER BY profit_to_avg_ratio DESC, profit_rank ASC
