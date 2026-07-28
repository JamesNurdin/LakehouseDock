WITH sales_agg AS (
    SELECT
        ws.ws_order_number,
        ws.ws_warehouse_sk,
        ws.ws_web_page_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    WHERE ws.ws_ext_wholesale_cost > 1000
      AND ws.ws_quantity BETWEEN 1 AND 100
      AND ws.ws_ship_hdemo_sk IN (1140, 4106, 4554)
    GROUP BY ws.ws_order_number, ws.ws_warehouse_sk, ws.ws_web_page_sk
),
returns_agg AS (
    SELECT
        wr.wr_order_number,
        wr.wr_web_page_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS returns_cnt
    FROM web_returns wr
    WHERE wr.wr_return_quantity > 10
      AND wr.wr_account_credit < 100
    GROUP BY wr.wr_order_number, wr.wr_web_page_sk
)
SELECT
    w.w_warehouse_id,
    w.w_city,
    w.w_state,
    wp.wp_url,
    s.total_sales,
    s.total_profit,
    COALESCE(r.total_return_amt, 0) AS total_return_amt,
    COALESCE(r.total_net_loss, 0) AS total_net_loss,
    (s.total_sales - COALESCE(r.total_return_amt, 0)) AS net_sales_after_returns,
    ROW_NUMBER() OVER (PARTITION BY w.w_state ORDER BY s.total_profit DESC) AS profit_rank_state,
    CASE WHEN s.total_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status,
    (
        SELECT AVG(wr_sub.wr_return_amt)
        FROM web_returns wr_sub
        WHERE wr_sub.wr_returned_date_sk = 2450
    ) AS avg_return_amt_sample
FROM sales_agg s
JOIN web_sales ws ON s.ws_order_number = ws.ws_order_number
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN returns_agg r ON ws.ws_order_number = r.wr_order_number
                         AND ws.ws_web_page_sk = r.wr_web_page_sk
WHERE wp.wp_type = 'Content'
  AND w.w_zip LIKE '74%'
  AND wp.wp_rec_start_date >= DATE '2001-01-01'
  AND w.w_gmt_offset BETWEEN -5.00 AND 5.00
  AND ws.ws_ship_cdemo_sk IN (41329, 67833, 484545)
ORDER BY net_sales_after_returns DESC
LIMIT 100
