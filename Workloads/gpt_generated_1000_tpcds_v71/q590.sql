WITH ws_agg AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_ext_sales_price) AS web_sales_total,
        SUM(ws.ws_quantity) AS web_quantity,
        COUNT(*) AS web_order_cnt
    FROM web_sales ws
    JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    WHERE d_ws.d_year = 2001
      AND ws.ws_ship_mode_sk IN (
          SELECT sm_ship_mode_sk
          FROM ship_mode
          WHERE sm_type = 'OVERNIGHT'
      )
    GROUP BY ws.ws_item_sk
)
SELECT
    d_sold.d_year,
    i.i_item_sk,
    i.i_category,
    s.s_store_name,
    w.w_warehouse_name,
    sm.sm_type,
    ib.ib_upper_bound,
    SUM(cs.cs_ext_sales_price) AS catalog_sales_total,
    ws_agg.web_sales_total,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
    CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN store s ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN web_site ws_site ON ws_site.web_open_date_sk = d_sold.d_date_sk
JOIN ws_agg ON ws_agg.ws_item_sk = cs.cs_item_sk
WHERE d_sold.d_year = 2001
  AND sm.sm_type = 'OVERNIGHT'
  AND ib.ib_upper_bound <= 50000
  AND i.i_brand = 'Brand#12'
GROUP BY
    d_sold.d_year,
    i.i_item_sk,
    i.i_category,
    s.s_store_name,
    w.w_warehouse_name,
    sm.sm_type,
    ib.ib_upper_bound,
    ws_agg.web_sales_total
ORDER BY catalog_sales_total DESC
LIMIT 100
