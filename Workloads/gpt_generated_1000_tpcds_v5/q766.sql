WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_date_sk
)
SELECT
    i.i_category,
    d_sold.d_year AS sales_year,
    SUM(ws.ws_ext_sales_price)          AS total_sales,
    SUM(ws.ws_net_profit)               AS total_profit,
    SUM(COALESCE(sr.sr_return_amt, 0))   AS total_store_returns,
    SUM(COALESCE(wr.wr_return_amt, 0))   AS total_web_returns,
    SUM(COALESCE(inv_agg.total_qty_on_hand, 0)) AS inventory_on_hand,
    COUNT(DISTINCT ws.ws_order_number)  AS orders_count
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
JOIN customer c_bill
    ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN household_demographics hd_bill
    ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN income_band ib
    ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
   AND sr.sr_returned_date_sk = d_sold.d_date_sk
LEFT JOIN reason r_sr
    ON sr.sr_reason_sk = r_sr.r_reason_sk
LEFT JOIN customer c_sr
    ON sr.sr_customer_sk = c_sr.c_customer_sk
LEFT JOIN household_demographics hd_sr
    ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
LEFT JOIN customer_address ca_sr
    ON sr.sr_addr_sk = ca_sr.ca_address_sk
LEFT JOIN date_dim d_sr_return
    ON sr.sr_returned_date_sk = d_sr_return.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = i.i_item_sk
LEFT JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
LEFT JOIN customer c_wr_refunded
    ON wr.wr_refunded_customer_sk = c_wr_refunded.c_customer_sk
LEFT JOIN household_demographics hd_wr_refunded
    ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
LEFT JOIN customer_address ca_wr_refunded
    ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
LEFT JOIN customer c_wr_returning
    ON wr.wr_returning_customer_sk = c_wr_returning.c_customer_sk
LEFT JOIN household_demographics hd_wr_returning
    ON wr.wr_returning_hdemo_sk = hd_wr_returning.hd_demo_sk
LEFT JOIN customer_address ca_wr_returning
    ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
LEFT JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
LEFT JOIN inv_agg
    ON inv_agg.inv_item_sk = i.i_item_sk
   AND inv_agg.inv_date_sk = d_sold.d_date_sk
WHERE
    i.i_category IN (
        SELECT i2.i_category
        FROM item i2
        WHERE i2.i_current_price > 200
    )
    AND ib.ib_lower_bound >= 50000
GROUP BY
    i.i_category,
    d_sold.d_year
ORDER BY
    total_sales DESC
LIMIT 100
