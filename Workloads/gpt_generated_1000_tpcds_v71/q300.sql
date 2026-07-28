WITH ss AS (
    SELECT
        ss_sold_date_sk,
        ss_item_sk,
        ss_customer_sk,
        ss_cdemo_sk,
        ss_hdemo_sk,
        ss_store_sk,
        ss_promo_sk,
        ss_ticket_number,
        ss_quantity,
        ss_net_paid,
        ss_net_profit
    FROM store_sales
),
ws AS (
    SELECT
        ws_sold_date_sk,
        ws_ship_date_sk,
        ws_item_sk,
        ws_bill_customer_sk,
        ws_bill_cdemo_sk,
        ws_bill_hdemo_sk,
        ws_ship_customer_sk,
        ws_ship_cdemo_sk,
        ws_ship_hdemo_sk,
        ws_ship_mode_sk,
        ws_warehouse_sk,
        ws_promo_sk,
        ws_order_number,
        ws_quantity,
        ws_net_paid,
        ws_net_profit
    FROM web_sales
),
wr AS (
    SELECT
        wr_returned_date_sk,
        wr_item_sk,
        wr_refunded_customer_sk,
        wr_refunded_cdemo_sk,
        wr_refunded_hdemo_sk,
        wr_returning_customer_sk,
        wr_returning_cdemo_sk,
        wr_returning_hdemo_sk,
        wr_reason_sk,
        wr_order_number,
        wr_return_amt,
        wr_net_loss
    FROM web_returns
)

SELECT
    d_sold.d_year,
    i.i_category,
    s.s_store_name,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_store_sales,
    SUM(ss.ss_net_paid) AS total_store_sales,
    SUM(ss.ss_net_profit) AS profit_store_sales,
    SUM(ws.ws_net_paid) AS total_web_sales,
    SUM(ws.ws_net_profit) AS profit_web_sales,
    SUM(wr.wr_return_amt) AS total_returns,
    COUNT(DISTINCT ws.ws_order_number) AS num_web_orders
FROM ss
JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN ws
    ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d_web_sold
    ON ws.ws_sold_date_sk = d_web_sold.d_date_sk
JOIN wr
    ON ws.ws_order_number = wr.wr_order_number
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_web_sold.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_ship.d_date_sk
WHERE d_sold.d_year = 2001
  AND i.i_brand = 'Brand#23'
  AND sm.sm_code = 'AIR'
  AND NOT EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_order_number = ws.ws_order_number
          AND wr2.wr_return_amt > 1000
    )
GROUP BY d_sold.d_year, i.i_category, s.s_store_name
HAVING SUM(ss.ss_net_paid) > 10000
ORDER BY total_store_sales DESC
LIMIT 100
