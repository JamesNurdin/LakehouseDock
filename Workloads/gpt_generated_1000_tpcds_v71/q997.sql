WITH sales_returns AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_promo_sk,
        ws.ws_ship_mode_sk,
        ws.ws_warehouse_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_ship_cdemo_sk,
        wr.wr_returned_date_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        p.p_promo_name,
        sm.sm_type,
        w.w_warehouse_name,
        d_sold.d_year AS sold_year,
        cd_bill.cd_marital_status,
        d_ship.d_month_seq,
        d_ret.d_year AS return_year
    FROM web_sales ws
    INNER JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    INNER JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    INNER JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    INNER JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    INNER JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    INNER JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    INNER JOIN customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    INNER JOIN customer_demographics cd_ship
        ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    INNER JOIN call_center cc
        ON cc.cc_open_date_sk = d_sold.d_date_sk
    INNER JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    INNER JOIN date_dim d_cc_closed
        ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    INNER JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    INNER JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    WHERE
        d_sold.d_year = 2001
        AND d_ship.d_month_seq BETWEEN 1200 AND 1250
        AND sm.sm_type IN ('AIR', 'RAIL')
        AND w.w_state = 'CA'
        AND cd_bill.cd_marital_status = 'M'
        AND p.p_discount_active = 'Y'
),
aggregated AS (
    SELECT
        p.p_promo_name            AS promo_name,
        sm.sm_type                AS ship_type,
        w.w_warehouse_name        AS warehouse_name,
        d_sold.d_year             AS year,
        SUM(ws.ws_net_profit)     AS total_net_profit,
        SUM(wr.wr_return_amt)     AS total_return_amount,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt
    FROM web_sales ws
    INNER JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    INNER JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    INNER JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    INNER JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    INNER JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    INNER JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    INNER JOIN call_center cc
        ON cc.cc_open_date_sk = d_sold.d_date_sk
    INNER JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    INNER JOIN date_dim d_cc_closed
        ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    INNER JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    INNER JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    INNER JOIN customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    INNER JOIN customer_demographics cd_ship
        ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    WHERE
        d_sold.d_year = 2001
        AND d_ship.d_month_seq BETWEEN 1200 AND 1250
        AND sm.sm_type IN ('AIR', 'RAIL')
        AND w.w_state = 'CA'
        AND cd_bill.cd_marital_status = 'M'
        AND p.p_discount_active = 'Y'
    GROUP BY ROLLUP (p.p_promo_name, sm.sm_type, w.w_warehouse_name, d_sold.d_year)
)
SELECT
    promo_name,
    ship_type,
    warehouse_name,
    year,
    total_net_profit,
    total_return_amount,
    order_cnt,
    RANK() OVER (PARTITION BY year ORDER BY total_net_profit DESC) AS profit_rank,
    SUM(total_net_profit) OVER (PARTITION BY year) AS year_total_profit
FROM aggregated
WHERE NOT (promo_name IS NULL AND ship_type IS NULL AND warehouse_name IS NULL)
ORDER BY year, profit_rank
LIMIT 100
