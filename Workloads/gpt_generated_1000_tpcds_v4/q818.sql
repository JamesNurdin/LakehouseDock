/*
Goal: Analyze web sales and associated returns by sales year, warehouse and household buying potential, compute adjusted sales for active promotions, and keep only groups with substantial sales volume.
*/
WITH ws AS (
    SELECT
        ws_order_number,
        ws_sold_date_sk,
        ws_ship_date_sk,
        ws_warehouse_sk,
        ws_promo_sk,
        ws_bill_hdemo_sk,
        ws_ship_hdemo_sk,
        ws_ext_sales_price,
        ws_net_profit,
        ws_item_sk
    FROM web_sales
),
wr AS (
    SELECT
        wr_order_number,
        wr_returned_date_sk,
        wr_reason_sk,
        wr_return_quantity,
        wr_return_amt,
        wr_net_loss,
        wr_refunded_hdemo_sk,
        wr_returning_hdemo_sk,
        wr_item_sk
    FROM web_returns
)
SELECT
    d_sold.d_year AS sales_year,
    w.w_warehouse_name,
    hd_bill.hd_buy_potential,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(CASE WHEN wr.wr_net_loss > 0 THEN wr.wr_net_loss ELSE 0 END) AS total_return_loss,
    SUM(
        CASE
            WHEN p.p_discount_active = 'Y' THEN ws.ws_ext_sales_price * 0.9
            ELSE ws.ws_ext_sales_price
        END
    ) AS adjusted_sales
FROM ws
JOIN wr
    ON ws.ws_order_number = wr.wr_order_number
   AND ws.ws_item_sk = wr.wr_item_sk
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN household_demographics hd_bill
    ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
    ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN household_demographics hd_refunded
    ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN household_demographics hd_returning
    ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
WHERE EXISTS (
    SELECT 1
    FROM promotion p2
    WHERE p2.p_promo_sk = ws.ws_promo_sk
      AND p2.p_discount_active = 'Y'
)
  AND d_sold.d_year BETWEEN 2000 AND 2002
  AND hd_bill.hd_buy_potential = '501-1000'
GROUP BY
    d_sold.d_year,
    w.w_warehouse_name,
    hd_bill.hd_buy_potential
HAVING SUM(ws.ws_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
