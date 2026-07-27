WITH joined_data AS (
  SELECT
    ws.ws_order_number,
    ws.ws_item_sk,
    ws.ws_sales_price,
    ws.ws_net_profit,
    i.i_category,
    i.i_brand,
    w.w_warehouse_name,
    wp.wp_type,
    wp.wp_rec_start_date,
    wp.wp_rec_end_date,
    wr.wr_return_amt
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
                        AND ws.ws_item_sk = wr.wr_item_sk
                        AND ws.ws_web_page_sk = wr.wr_web_page_sk
  WHERE i.i_category = 'Sports'
    AND i.i_brand = 'Brand#12'
    AND wp.wp_rec_start_date >= DATE '2000-01-01'
    AND w.w_gmt_offset = -6.00
),
avg_return_per_item AS (
  SELECT
    i.i_item_sk,
    AVG(wr.wr_return_amt) AS avg_ret_amt
  FROM web_returns wr
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  GROUP BY i.i_item_sk
),
unioned AS (
  SELECT
    jd.ws_order_number,
    jd.ws_item_sk,
    jd.ws_sales_price AS amount,
    jd.ws_net_profit,
    jd.i_category,
    jd.i_brand,
    jd.w_warehouse_name,
    jd.wp_type,
    'sale' AS rec_type
  FROM joined_data jd
  WHERE jd.ws_sales_price > 50

  UNION ALL

  SELECT
    jd.ws_order_number,
    jd.ws_item_sk,
    jd.wr_return_amt AS amount,
    jd.ws_net_profit,
    jd.i_category,
    jd.i_brand,
    jd.w_warehouse_name,
    jd.wp_type,
    'return' AS rec_type
  FROM joined_data jd
  WHERE jd.wr_return_amt IS NOT NULL
    AND jd.wr_return_amt > 5
)
SELECT
  u.rec_type,
  u.ws_order_number,
  u.amount,
  u.i_category,
  u.i_brand,
  u.w_warehouse_name,
  u.wp_type,
  COALESCE(ari.avg_ret_amt, 0) AS avg_ret_amt,
  CASE
    WHEN u.amount > COALESCE(ari.avg_ret_amt, 0) THEN 'Above Avg Return'
    ELSE 'Below Avg Return'
  END AS amount_vs_avg,
  RANK() OVER (PARTITION BY u.rec_type ORDER BY u.amount DESC) AS amount_rank,
  ROW_NUMBER() OVER (ORDER BY u.ws_order_number) AS row_num
FROM unioned u
LEFT JOIN avg_return_per_item ari ON ari.i_item_sk = u.ws_item_sk
ORDER BY amount_rank
LIMIT 100
