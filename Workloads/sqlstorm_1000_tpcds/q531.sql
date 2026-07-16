WITH sales_agg_raw AS (
 SELECT i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        d.d_year AS sales_year,
        cs.cs_ext_sales_price AS sales_amount,
        cs.cs_quantity AS quantity,
        cs.cs_net_profit AS profit
 FROM catalog_sales cs
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 UNION ALL
 SELECT i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        d.d_year AS sales_year,
        ss.ss_ext_sales_price AS sales_amount,
        ss.ss_quantity AS quantity,
        ss.ss_net_profit AS profit
 FROM store_sales ss
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 UNION ALL
 SELECT i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        d.d_year AS sales_year,
        ws.ws_ext_sales_price AS sales_amount,
        ws.ws_quantity AS quantity,
        ws.ws_net_profit AS profit
 FROM web_sales ws
 JOIN item i ON ws.ws_item_sk = i.i_item_sk
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
),
sales_agg AS (
 SELECT i_item_sk,
        i_item_id,
        i_item_desc,
        sales_year,
        SUM(sales_amount) AS total_sales_amount,
        SUM(quantity) AS total_quantity,
        SUM(profit) AS total_profit
 FROM sales_agg_raw
 GROUP BY i_item_sk, i_item_id, i_item_desc, sales_year
),
returns_agg_raw AS (
 SELECT i.i_item_sk,
        d.d_year AS sales_year,
        cr.cr_return_amt_inc_tax AS return_amount,
        cr.cr_return_quantity AS return_quantity
 FROM catalog_returns cr
 JOIN item i ON cr.cr_item_sk = i.i_item_sk
 JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
 UNION ALL
 SELECT i.i_item_sk,
        d.d_year AS sales_year,
        sr.sr_return_amt_inc_tax AS return_amount,
        sr.sr_return_quantity AS return_quantity
 FROM store_returns sr
 JOIN item i ON sr.sr_item_sk = i.i_item_sk
 JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
 UNION ALL
 SELECT i.i_item_sk,
        d.d_year AS sales_year,
        wr.wr_return_amt_inc_tax AS return_amount,
        wr.wr_return_quantity AS return_quantity
 FROM web_returns wr
 JOIN item i ON wr.wr_item_sk = i.i_item_sk
 JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
),
returns_agg AS (
 SELECT i_item_sk,
        sales_year,
        SUM(return_amount) AS total_return_amount,
        SUM(return_quantity) AS total_return_quantity
 FROM returns_agg_raw
 GROUP BY i_item_sk, sales_year
),
combined AS (
 SELECT s.i_item_sk,
        s.i_item_id,
        s.i_item_desc,
        s.sales_year,
        s.total_sales_amount,
        s.total_quantity,
        s.total_profit,
        COALESCE(r.total_return_amount, 0) AS total_return_amount,
        COALESCE(r.total_return_quantity, 0) AS total_return_quantity
 FROM sales_agg s
 LEFT JOIN returns_agg r
   ON s.i_item_sk = r.i_item_sk
  AND s.sales_year = r.sales_year
),
ranked AS (
 SELECT *,
        ROW_NUMBER() OVER (PARTITION BY sales_year ORDER BY total_profit DESC) AS profit_rank
 FROM combined
)
SELECT sales_year,
       i_item_id,
       i_item_desc,
       total_sales_amount,
       total_quantity,
       total_profit,
       total_return_amount,
       total_return_quantity,
       CASE WHEN total_sales_amount = 0 THEN NULL
            ELSE total_return_amount / total_sales_amount END AS return_rate,
       profit_rank
FROM ranked
WHERE profit_rank <= 10
ORDER BY sales_year, profit_rank
