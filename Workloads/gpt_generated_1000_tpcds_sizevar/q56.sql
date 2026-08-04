WITH detailed_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        i.i_color AS i_color,
        ib.ib_lower_bound AS ib_lower_bound,
        ws.ws_net_paid AS ws_net_paid,
        ws.ws_net_profit AS ws_net_profit,
        wr.wr_return_amt AS wr_return_amt,
        wr.wr_return_quantity AS wr_return_quantity
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca_ship
        ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN household_demographics hd_ship
        ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
    LEFT JOIN customer_address ca_returning
        ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
    LEFT JOIN household_demographics hd_returning
        ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
    LEFT JOIN customer_address ca_refunded
        ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
    LEFT JOIN household_demographics hd_refunded
        ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
)
SELECT
    i_color,
    ib_lower_bound,
    SUM(ws_net_paid) AS total_sales,
    SUM(COALESCE(wr_return_amt, 0)) AS total_return_amount,
    SUM(ws_net_profit) AS total_profit,
    COUNT(DISTINCT ws_order_number) AS distinct_orders,
    ROW_NUMBER() OVER (ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
FROM detailed_sales
GROUP BY i_color, ib_lower_bound
ORDER BY total_sales DESC
LIMIT 100
