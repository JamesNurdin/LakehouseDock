WITH cat_data AS (
    SELECT
        cr.cr_order_number,
        SUM(cr.cr_return_amount)               AS total_return_amount,
        SUM(cr.cr_fee)                         AS total_return_fee,
        SUM(cs.cs_net_profit)                 AS total_sales_profit,
        cs.cs_sold_date_sk,
        cs.cs_warehouse_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    WHERE cr.cr_returned_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2001
    )
    GROUP BY
        cr.cr_order_number,
        cs.cs_sold_date_sk,
        cs.cs_warehouse_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk
),
web_data AS (
    SELECT
        wr.wr_order_number,
        SUM(wr.wr_return_amt)                 AS total_web_return_amt,
        SUM(wr.wr_fee)                         AS total_web_return_fee,
        SUM(ws.ws_net_profit)                 AS total_web_sales_profit,
        ws.ws_sold_date_sk,
        ws.ws_warehouse_sk,
        ws.ws_bill_customer_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_bill_addr_sk
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    WHERE wr.wr_returned_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2002
    )
    GROUP BY
        wr.wr_order_number,
        ws.ws_sold_date_sk,
        ws.ws_warehouse_sk,
        ws.ws_bill_customer_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_bill_addr_sk
)
SELECT
    d.d_year,
    w.w_state,
    hd.hd_buy_potential,
    SUM(
        COALESCE(cat_data.total_sales_profit, 0) +
        COALESCE(web_data.total_web_sales_profit, 0) -
        COALESCE(cat_data.total_return_amount, 0) -
        COALESCE(web_data.total_web_return_amt, 0)
    )                                    AS net_profit_after_returns,
    COUNT(DISTINCT cat_data.cr_order_number) AS catalog_orders,
    COUNT(DISTINCT web_data.wr_order_number) AS web_orders
FROM cat_data
LEFT JOIN web_data
    ON cat_data.cs_bill_customer_sk = web_data.ws_bill_customer_sk
    AND cat_data.cs_sold_date_sk = web_data.ws_sold_date_sk
JOIN date_dim d
    ON cat_data.cs_sold_date_sk = d.d_date_sk
JOIN warehouse w
    ON cat_data.cs_warehouse_sk = w.w_warehouse_sk
JOIN household_demographics hd
    ON cat_data.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
    ON cat_data.cs_bill_addr_sk = ca.ca_address_sk
JOIN customer c
    ON cat_data.cs_bill_customer_sk = c.c_customer_sk
WHERE w.w_state = 'CA'
  AND c.c_birth_year BETWEEN 1950 AND 1960
  AND hd.hd_vehicle_count > 2
  AND ca.ca_gmt_offset = -5.00
  AND d.d_month_seq = 12
GROUP BY d.d_year, w.w_state, hd.hd_buy_potential
ORDER BY net_profit_after_returns DESC
LIMIT 100
