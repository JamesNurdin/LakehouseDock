WITH sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_brand,
        'store' AS channel,
        SUM(ss.ss_ext_sales_price) AS sales,
        SUM(ss.ss_net_profit) AS profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS orders
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_color = 'BLUE'
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_brand
    UNION ALL
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_brand,
        'catalog' AS channel,
        SUM(cs.cs_ext_sales_price) AS sales,
        SUM(cs.cs_net_profit) AS profit,
        COUNT(DISTINCT cs.cs_order_number) AS orders
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_color = 'BLUE'
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_brand
    UNION ALL
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_brand,
        'web' AS channel,
        SUM(ws.ws_ext_sales_price) AS sales,
        SUM(ws.ws_net_profit) AS profit,
        COUNT(DISTINCT ws.ws_order_number) AS orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_color = 'BLUE'
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_brand
),
returns AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_brand,
        'store' AS channel,
        SUM(sr.sr_return_amt) AS return_amount
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_color = 'BLUE'
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_brand
    UNION ALL
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_brand,
        'catalog' AS channel,
        SUM(cr.cr_return_amount) AS return_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_color = 'BLUE'
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_brand
    UNION ALL
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_brand,
        'web' AS channel,
        SUM(wr.wr_return_amt) AS return_amount
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_color = 'BLUE'
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_brand
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.i_category,
    s.i_brand,
    s.channel,
    s.sales - COALESCE(r.return_amount, 0) AS net_sales,
    s.profit,
    s.orders,
    (s.sales - COALESCE(r.return_amount, 0)) / NULLIF(s.profit, 0) AS sales_to_profit_ratio,
    ROW_NUMBER() OVER (PARTITION BY s.channel, s.i_category ORDER BY (s.sales - COALESCE(r.return_amount, 0)) DESC) AS brand_rank
FROM sales s
LEFT JOIN returns r
  ON s.d_year = r.d_year
 AND s.d_month_seq = r.d_month_seq
 AND s.i_category = r.i_category
 AND s.i_brand = r.i_brand
 AND s.channel = r.channel
ORDER BY net_sales DESC
LIMIT 100
