WITH sales_agg AS (
  SELECT ws.ws_item_sk,
         d.d_year,
         d.d_month_seq,
         ws.ws_web_page_sk,
         SUM(ws.ws_quantity) AS sold_qty,
         MIN(wp.wp_url) AS page_url
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  GROUP BY ws.ws_item_sk, d.d_year, d.d_month_seq, ws.ws_web_page_sk
),
returns_agg AS (
  SELECT ws.ws_item_sk,
         d.d_year,
         d.d_month_seq,
         ws.ws_web_page_sk,
         SUM(wr.wr_return_quantity) AS returned_qty
  FROM web_returns wr
  JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
                    AND wr.wr_item_sk = ws.ws_item_sk
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  GROUP BY ws.ws_item_sk, d.d_year, d.d_month_seq, ws.ws_web_page_sk
)
SELECT s.d_year,
       s.d_month_seq,
       s.ws_item_sk,
       s.page_url,
       s.sold_qty,
       COALESCE(r.returned_qty, 0) AS returned_qty,
       CASE WHEN s.sold_qty = 0 THEN 0
            ELSE CAST(COALESCE(r.returned_qty, 0) AS double) / s.sold_qty END AS return_rate,
       RANK() OVER (PARTITION BY s.d_year, s.d_month_seq ORDER BY 
            CASE WHEN s.sold_qty = 0 THEN 0 ELSE COALESCE(r.returned_qty, 0) / s.sold_qty END DESC) AS return_rate_rank
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.ws_item_sk = r.ws_item_sk
 AND s.d_year = r.d_year
 AND s.d_month_seq = r.d_month_seq
 AND s.ws_web_page_sk = r.ws_web_page_sk
ORDER BY s.d_year DESC, s.d_month_seq DESC, return_rate_rank
