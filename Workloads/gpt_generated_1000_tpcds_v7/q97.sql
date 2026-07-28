WITH ws AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_ship_hdemo_sk,
        ws.ws_wholesale_cost,
        ws.ws_list_price,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_ext_discount_amt,
        ws.ws_ext_sales_price,
        ws.ws_ext_tax,
        ws.ws_net_paid,
        ws.ws_net_profit
    FROM tpcds.web_sales ws
)
SELECT
    cc.cc_name,
    dd_sold.d_year,
    hd.hd_buy_potential,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ws.ws_order_number) AS orders_cnt,
    MIN(ws.ws_net_paid) AS min_net_paid,
    MAX(ws.ws_net_paid) AS max_net_paid
FROM ws
JOIN tpcds.date_dim dd_sold
    ON ws.ws_sold_date_sk = dd_sold.d_date_sk
JOIN tpcds.date_dim dd_ship
    ON ws.ws_ship_date_sk = dd_ship.d_date_sk
JOIN tpcds.household_demographics hd
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.inventory inv
    ON inv.inv_date_sk = dd_sold.d_date_sk
JOIN tpcds.call_center cc
    ON cc.cc_open_date_sk = dd_sold.d_date_sk
WHERE dd_sold.d_date >= DATE '2001-01-01'
  AND dd_sold.d_date <= DATE '2001-12-31'
  AND dd_ship.d_quarter_seq = 5
  AND hd.hd_buy_potential = '1001-5000'
  AND inv.inv_quantity_on_hand > 200
  AND cc.cc_state = 'CA'
GROUP BY cc.cc_name, dd_sold.d_year, hd.hd_buy_potential
ORDER BY total_sales DESC
LIMIT 100
