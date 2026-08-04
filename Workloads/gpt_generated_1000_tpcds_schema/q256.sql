WITH returns_agg AS (
    SELECT
        wr.wr_order_number,
        COUNT(*) AS return_cnt,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND d.d_month_seq BETWEEN 1200 AND 1211
    GROUP BY wr.wr_order_number
)
SELECT
    cc.cc_name,
    ca_bill.ca_city,
    d.d_year,
    hd.hd_buy_potential,
    ib.ib_upper_bound,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_net_profit) AS avg_profit,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    SUM(CASE WHEN ws.ws_net_profit > 0 THEN ws.ws_ext_sales_price ELSE 0 END) AS profit_sales,
    ROW_NUMBER() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank,
    returns_agg.return_cnt,
    returns_agg.total_return_amt
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
LEFT JOIN returns_agg ON ws.ws_order_number = returns_agg.wr_order_number
WHERE d.d_year = 2002
  AND d.d_fy_quarter_seq = 14
  AND cc.cc_state = 'CA'
  AND ca_bill.ca_location_type = 'single family'
  AND hd.hd_vehicle_count > 0
  AND ib.ib_upper_bound <= 60000
  AND ws.ws_list_price BETWEEN 20 AND 200
GROUP BY
    cc.cc_name,
    ca_bill.ca_city,
    d.d_year,
    hd.hd_buy_potential,
    ib.ib_upper_bound,
    returns_agg.return_cnt,
    returns_agg.total_return_amt
ORDER BY total_sales DESC
LIMIT 100
