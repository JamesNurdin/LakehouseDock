WITH
    sales AS (
        SELECT
            ws.ws_order_number,
            ws.ws_sold_date_sk,
            ws.ws_ship_date_sk,
            ws.ws_item_sk,
            ws.ws_quantity,
            ws.ws_net_profit,
            ws.ws_bill_cdemo_sk,
            ws.ws_ship_cdemo_sk,
            ws.ws_ship_mode_sk,
            ws.ws_warehouse_sk
        FROM web_sales ws
    ),
    returns AS (
        SELECT
            wr.wr_order_number,
            wr.wr_return_amt,
            wr.wr_return_quantity
        FROM web_returns wr
    ),
    order_excluded AS (
        SELECT ws_order_number FROM web_sales
        EXCEPT
        SELECT wr_order_number FROM web_returns
    ),
    joined AS (
        SELECT
            s.ws_order_number,
            d_sold.d_year AS sold_year,
            d_ship.d_month_seq AS ship_month_seq,
            i.i_category,
            i.i_current_price,
            cd_bill.cd_credit_rating,
            cd_ship.cd_gender,
            sm.sm_type,
            w.w_warehouse_name,
            cp.cp_catalog_number,
            inv.inv_quantity_on_hand,
            s.ws_quantity,
            s.ws_net_profit,
            CASE WHEN s.ws_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status,
            (
                SELECT COUNT(*)
                FROM returns r
                WHERE r.wr_order_number = s.ws_order_number
            ) AS return_count,
            inv_calc.inventory_value
        FROM sales s
        JOIN date_dim d_sold ON s.ws_sold_date_sk = d_sold.d_date_sk
        JOIN date_dim d_ship ON s.ws_ship_date_sk = d_ship.d_date_sk
        JOIN item i ON s.ws_item_sk = i.i_item_sk
        JOIN customer_demographics cd_bill ON s.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
        JOIN customer_demographics cd_ship ON s.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
        JOIN ship_mode sm ON s.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON s.ws_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN web_returns wr ON s.ws_order_number = wr.wr_order_number
        JOIN catalog_page cp ON cp.cp_start_date_sk = d_sold.d_date_sk
        FULL OUTER JOIN inventory inv
            ON inv.inv_item_sk = i.i_item_sk
            AND inv.inv_date_sk = d_sold.d_date_sk
        CROSS JOIN LATERAL (
            SELECT inv.inv_quantity_on_hand * i.i_current_price AS inventory_value
        ) AS inv_calc
        WHERE s.ws_order_number IN (SELECT ws_order_number FROM order_excluded)
    )
SELECT
    profit_status,
    sold_year,
    ship_month_seq,
    i_category,
    COUNT(*) AS order_cnt,
    SUM(ws_quantity) AS total_quantity,
    AVG(ws_net_profit) AS avg_profit,
    SUM(CASE WHEN return_count > 0 THEN 1 ELSE 0 END) AS orders_with_returns,
    SUM(inventory_value) AS total_inventory_value
FROM joined
GROUP BY profit_status, sold_year, ship_month_seq, i_category
ORDER BY order_cnt DESC
LIMIT 100
