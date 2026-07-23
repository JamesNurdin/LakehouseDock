WITH sales_agg AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_class,
        sm.sm_ship_mode_id,
        sm.sm_carrier,
        hd_bill.hd_buy_potential AS bill_buy_potential,
        hd_ship.hd_buy_potential AS ship_buy_potential,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales_amount,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_return_loss
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
    WHERE
        i.i_class = 'accessories'
        AND sm.sm_carrier = 'DHL'
        AND hd_bill.hd_buy_potential = '5001-10000'
        AND i.i_manufact_id IN (169, 350)
        AND ws.ws_quantity > 0
    GROUP BY
        ws.ws_order_number,
        ws.ws_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_class,
        sm.sm_ship_mode_id,
        sm.sm_carrier,
        hd_bill.hd_buy_potential,
        hd_ship.hd_buy_potential
),
item_ship_agg AS (
    SELECT
        s.i_item_id,
        s.i_brand,
        s.i_class,
        s.sm_ship_mode_id,
        s.sm_carrier,
        SUM(s.total_quantity) AS total_quantity,
        SUM(s.total_net_profit) AS total_net_profit,
        SUM(s.total_return_quantity) AS total_return_quantity,
        SUM(s.total_return_amount) AS total_return_amount,
        SUM(s.total_sales_amount) AS total_sales_amount
    FROM sales_agg s
    GROUP BY
        s.i_item_id,
        s.i_brand,
        s.i_class,
        s.sm_ship_mode_id,
        s.sm_carrier
)
SELECT
    isa.i_item_id,
    isa.i_brand,
    isa.i_class,
    isa.sm_ship_mode_id,
    isa.sm_carrier,
    isa.total_quantity,
    isa.total_net_profit,
    isa.total_return_quantity,
    isa.total_return_amount,
    CASE WHEN isa.total_quantity = 0 THEN 0 ELSE isa.total_return_quantity / isa.total_quantity END AS return_rate,
    CASE WHEN isa.total_sales_amount = 0 THEN 0 ELSE isa.total_net_profit / isa.total_sales_amount END AS profit_margin,
    isa.total_net_profit / total_all.total_net_profit AS profit_share
FROM item_ship_agg isa
CROSS JOIN (
    SELECT SUM(total_net_profit) AS total_net_profit FROM item_ship_agg
) total_all
WHERE
    isa.total_net_profit > 0
    AND isa.total_quantity >= 10
    AND (CASE WHEN isa.total_quantity = 0 THEN 0 ELSE isa.total_return_quantity / isa.total_quantity END) < 0.2
    AND (CASE WHEN isa.total_sales_amount = 0 THEN 0 ELSE isa.total_net_profit / isa.total_sales_amount END) > 0.15
    AND isa.total_net_profit / total_all.total_net_profit > 0.01
ORDER BY isa.total_net_profit DESC
LIMIT 100
