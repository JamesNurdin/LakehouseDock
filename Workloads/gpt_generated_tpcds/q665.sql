WITH catalog AS (
    SELECT
        i.i_category AS i_category,
        d.d_year AS d_year,
        d.d_month_seq AS d_month_seq,
        SUM(cs.cs_net_paid) AS sales,
        SUM(cr.cr_return_amount) AS returns
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
       AND cs.cs_item_sk = cr.cr_item_sk
    GROUP BY i.i_category, d.d_year, d.d_month_seq
),
web AS (
    SELECT
        i.i_category AS i_category,
        d.d_year AS d_year,
        d.d_month_seq AS d_month_seq,
        SUM(ws.ws_net_paid) AS sales,
        SUM(wr.wr_return_amt) AS returns
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
       AND ws.ws_item_sk = wr.wr_item_sk
    GROUP BY i.i_category, d.d_year, d.d_month_seq
),
combined AS (
    SELECT i_category, d_year, d_month_seq, sales, returns FROM catalog
    UNION ALL
    SELECT i_category, d_year, d_month_seq, sales, returns FROM web
)
SELECT
    i_category,
    d_year,
    d_month_seq,
    SUM(sales) AS total_sales,
    SUM(returns) AS total_returns,
    SUM(sales) - COALESCE(SUM(returns), 0) AS net_revenue
FROM combined
WHERE d_year = 2001
GROUP BY i_category, d_year, d_month_seq
ORDER BY i_category, d_year, d_month_seq
