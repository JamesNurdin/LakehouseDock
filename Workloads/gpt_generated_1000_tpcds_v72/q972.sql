WITH sales_agg AS (
    SELECT
        ws_item_sk,
        ws_sold_date_sk,
        ws_sold_time_sk,
        ws_warehouse_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity,
        COUNT(*) AS sales_cnt
    FROM web_sales
    WHERE ws_ext_sales_price > 1000
      AND ws_quantity >= 1
      AND ws_ext_discount_amt < 500
      AND ws_coupon_amt BETWEEN 0 AND 2000
    GROUP BY ws_item_sk, ws_sold_date_sk, ws_sold_time_sk, ws_warehouse_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    w.w_warehouse_name,
    t.t_hour,
    ib.ib_upper_bound,
    hd.hd_buy_potential,
    cd.cd_credit_rating,
    ws_agg.total_sales,
    ws_agg.total_quantity,
    RANK() OVER (PARTITION BY w.w_warehouse_name ORDER BY ws_agg.total_sales DESC) AS sales_rank,
    CASE WHEN EXISTS (
            SELECT 1
            FROM web_returns wr
            WHERE wr.wr_order_number = ws.ws_order_number
              AND wr.wr_return_amt > 0
        ) THEN 'Returned' ELSE 'No Return' END AS return_flag
FROM sales_agg ws_agg
JOIN web_sales ws
  ON ws.ws_item_sk = ws_agg.ws_item_sk
 AND ws.ws_sold_date_sk = ws_agg.ws_sold_date_sk
 AND ws.ws_sold_time_sk = ws_agg.ws_sold_time_sk
 AND ws.ws_warehouse_sk = ws_agg.ws_warehouse_sk
JOIN item i
  ON ws.ws_item_sk = i.i_item_sk
JOIN warehouse w
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN time_dim t
  ON ws.ws_sold_time_sk = t.t_time_sk
JOIN customer_demographics cd
  ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site site
  ON ws.ws_web_site_sk = site.web_site_sk
WHERE i.i_current_price BETWEEN 10 AND 1000
  AND w.w_state = 'CA'
  AND t.t_hour BETWEEN 9 AND 17
  AND wp.wp_autogen_flag = 'N'
  AND cd.cd_gender = 'M'
  AND ib.ib_upper_bound >= 50000
  AND hd.hd_buy_potential = '1001-5000'
ORDER BY ws_agg.total_sales DESC, i.i_item_id
LIMIT 100
