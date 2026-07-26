WITH returns_agg AS (
   SELECT wr.wr_item_sk AS item_sk,
          d.d_quarter_seq AS quarter_seq,
          SUM(wr.wr_return_quantity) AS total_return_qty,
          SUM(wr.wr_return_amt_inc_tax) AS total_return_amt,
          MAX(t.t_hour) AS max_return_hour
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
   GROUP BY wr.wr_item_sk, d.d_quarter_seq
), sales_agg AS (
   SELECT ws.ws_item_sk AS item_sk,
          d.d_quarter_seq AS quarter_seq,
          SUM(ws.ws_quantity) AS total_sold_qty,
          SUM(ws.ws_ext_sales_price) AS total_sales_amt,
          MAX(t.t_hour) AS max_sales_hour
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
   GROUP BY ws.ws_item_sk, d.d_quarter_seq
), joined AS (
   SELECT r.item_sk,
          r.quarter_seq,
          r.total_return_qty,
          r.total_return_amt,
          r.max_return_hour,
          s.total_sold_qty,
          s.total_sales_amt,
          s.max_sales_hour,
          (r.total_return_qty * 1.0) / NULLIF(s.total_sold_qty,0) AS return_rate,
          (r.total_return_amt * 1.0) / NULLIF(s.total_sales_amt,0) AS return_amount_ratio,
          SUM(r.total_return_amt) OVER (PARTITION BY r.quarter_seq) AS quarter_return_total,
          ROW_NUMBER() OVER (PARTITION BY r.quarter_seq ORDER BY r.total_return_amt DESC) AS rn
   FROM returns_agg r
   LEFT JOIN sales_agg s ON r.item_sk = s.item_sk AND r.quarter_seq = s.quarter_seq
)
SELECT item_sk,
       quarter_seq,
       total_return_qty,
       total_return_amt,
       total_sold_qty,
       total_sales_amt,
       max_return_hour,
       max_sales_hour,
       return_rate,
       return_amount_ratio,
       quarter_return_total
FROM joined
WHERE rn <= 4
ORDER BY quarter_seq, rn
