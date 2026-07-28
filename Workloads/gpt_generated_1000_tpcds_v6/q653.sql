WITH base AS (
    SELECT
        ca_bill.ca_state AS state,
        i.i_brand AS brand,
        ws.ws_net_profit AS net_profit,
        wr.wr_return_amt AS return_amt,
        ws.ws_order_number AS order_number
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer c_ship ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
    JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        AND p.p_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
    LEFT JOIN catalog_page cp ON cp.cp_start_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2000
      AND i.i_current_price > 50
      AND sm.sm_carrier = 'AIRBORNE'
      AND p.p_discount_active = 'Y'
),
agg1 AS (
    SELECT
        state,
        brand,
        SUM(net_profit) AS total_profit,
        SUM(return_amt) AS total_return,
        COUNT(DISTINCT order_number) AS order_cnt
    FROM base
    GROUP BY GROUPING SETS (
        (state, brand),
        (state),
        (brand),
        ()
    )
),
agg2 AS (
    SELECT
        state,
        AVG(total_profit) AS avg_profit,
        SUM(total_return) AS sum_return,
        order_cnt
    FROM agg1
    WHERE total_profit IS NOT NULL
    GROUP BY state, order_cnt
)
SELECT *
FROM (
    SELECT
        state,
        brand,
        total_profit,
        total_return,
        order_cnt
    FROM agg1
    WHERE total_profit > 10000

    UNION ALL

    SELECT
        state,
        NULL AS brand,
        avg_profit AS total_profit,
        sum_return AS total_return,
        order_cnt
    FROM agg2
    WHERE avg_profit > 5000
) final_result
ORDER BY state ASC, total_profit DESC
