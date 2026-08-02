WITH base_sales AS (
  SELECT
    ws.ws_item_sk,
    ws.ws_quantity,
    ws.ws_ext_sales_price,
    ws.ws_net_profit,
    ws.ws_ext_discount_amt,
    ws.ws_ship_mode_sk,
    ws.ws_sold_time_sk,
    i.i_item_id,
    i.i_product_name,
    i.i_item_desc,
    i.i_brand,
    i.i_category,
    i.i_rec_start_date,
    i.i_rec_end_date,
    REGEXP_EXTRACT(i.i_item_desc, '(\\d+)', 1) AS extracted_number,
    CONCAT(i.i_brand, ' - ', i.i_product_name) AS brand_product,
    sm.sm_carrier,
    tp.t_am_pm,
    wp.wp_url
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN time_dim tp ON ws.ws_sold_time_sk = tp.t_time_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  WHERE REGEXP_LIKE(i.i_item_desc, '\\d{2,}')
    AND i.i_product_name LIKE '%Gold%'
    AND i.i_rec_start_date >= DATE '2000-01-01'
    AND i.i_rec_end_date <= DATE '2002-12-31'
    AND sm.sm_carrier LIKE 'FedEx%'
    AND tp.t_am_pm = 'PM'
),
item_agg AS (
  SELECT
    bs.ws_item_sk AS i_item_sk,
    MIN(bs.i_item_id) AS i_item_id,
    MIN(bs.i_product_name) AS i_product_name,
    MIN(bs.i_brand) AS i_brand,
    MIN(bs.i_category) AS i_category,
    MIN(bs.extracted_number) AS extracted_number,
    MIN(bs.brand_product) AS brand_product,
    MIN(bs.sm_carrier) AS sm_carrier,
    MIN(bs.i_rec_start_date) AS rec_start_date,
    MAX(bs.i_rec_end_date) AS rec_end_date,
    SUM(bs.ws_quantity) AS total_quantity,
    SUM(bs.ws_ext_sales_price) AS total_sales,
    SUM(bs.ws_net_profit) AS total_profit,
    AVG(bs.ws_ext_discount_amt) AS avg_discount
  FROM base_sales bs
  GROUP BY bs.ws_item_sk
),
item_windowed AS (
  SELECT
    i_item_sk,
    i_item_id,
    i_product_name,
    i_brand,
    i_category,
    extracted_number,
    brand_product,
    sm_carrier,
    rec_start_date,
    rec_end_date,
    total_quantity,
    total_sales,
    total_profit,
    avg_discount,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_profit DESC) AS rn_category,
    SUM(total_sales) OVER (PARTITION BY i_brand ORDER BY total_profit DESC ROWS UNBOUNDED PRECEDING) AS cum_sales_by_brand
  FROM item_agg
)
SELECT
  i_item_id,
  i_product_name,
  i_brand,
  i_category,
  extracted_number,
  brand_product,
  sm_carrier,
  rec_start_date,
  rec_end_date,
  total_quantity,
  total_sales,
  total_profit,
  avg_discount,
  total_profit / (SELECT AVG(wr_return_amt) FROM web_returns) AS profit_to_avg_return_ratio,
  cum_sales_by_brand
FROM item_windowed iw
WHERE iw.total_sales > (SELECT AVG(ws_ext_sales_price) FROM web_sales)
  AND iw.rn_category = 1
  AND EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_item_sk = iw.i_item_sk
          AND wr.wr_return_amt > 0
      )
ORDER BY cum_sales_by_brand DESC, total_profit DESC
LIMIT 100
