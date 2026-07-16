WITH
sales_agg AS (
    SELECT
        i.i_category AS category,
        ca.ca_state AS state,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders,
        AVG(ws.ws_sales_price) AS avg_price
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2451000
      AND ws.ws_net_paid > 0
      AND hd.hd_income_band_sk >= 5
    GROUP BY i.i_category, ca.ca_state
),
returns_agg AS (
    SELECT
        i.i_category AS category,
        ca.ca_state AS state,
        SUM(sr.sr_refunded_cash) AS total_refunds,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        COUNT(DISTINCT sr.sr_ticket_number) AS num_returns
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450000 AND 2451000
      AND sr.sr_refunded_cash > 0
      AND hd.hd_income_band_sk >= 5
    GROUP BY i.i_category, ca.ca_state
)
SELECT
    s.category,
    s.state,
    s.total_sales,
    s.total_profit,
    r.total_refunds,
    r.total_return_qty,
    CASE WHEN s.total_sales > 0 THEN r.total_refunds / s.total_sales ELSE NULL END AS refund_to_sales_ratio,
    RANK() OVER (ORDER BY s.total_profit DESC) AS profit_rank
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.category = r.category AND s.state = r.state
WHERE s.total_sales > 10000
ORDER BY s.total_profit DESC
LIMIT 100
