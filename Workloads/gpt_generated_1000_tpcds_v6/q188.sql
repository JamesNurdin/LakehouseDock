WITH sales_agg AS (
  SELECT
    d_sold.d_year AS sale_year,
    i.i_category AS category,
    cd_bill.cd_gender AS gender,
    CASE WHEN ws.ws_quantity > 5 THEN 'Bulk' ELSE 'Regular' END AS order_type,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    COUNT(*) AS sales_cnt
  FROM web_sales ws
  JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
  JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
  JOIN time_dim t
    ON ws.ws_sold_time_sk = t.t_time_sk
  JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
  JOIN customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
  WHERE d_sold.d_year BETWEEN 2000 AND 2002
    AND i.i_current_price > 100
    AND sm.sm_carrier = 'DIAMOND'
    AND EXISTS (
      SELECT 1 FROM ship_mode sm2
      WHERE sm2.sm_ship_mode_sk = ws.ws_ship_mode_sk
        AND sm2.sm_contract = 'I3uCelXtjP'
    )
  GROUP BY
    d_sold.d_year,
    i.i_category,
    cd_bill.cd_gender,
    CASE WHEN ws.ws_quantity > 5 THEN 'Bulk' ELSE 'Regular' END
)
SELECT
  sale_year,
  category,
  gender,
  order_type,
  total_profit,
  avg_discount,
  sales_cnt,
  total_profit / NULLIF(sales_cnt, 0) AS profit_per_sale
FROM sales_agg
WHERE total_profit > 10000
  AND avg_discount < 500
  AND sales_cnt >= 50
ORDER BY total_profit DESC
LIMIT 100
