WITH data AS (
    SELECT d.d_year AS d_year,
           i.i_category AS i_category,
           cs.cs_net_paid AS amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year,
           i.i_category,
           ss.ss_net_paid
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year,
           i.i_category,
           ws.ws_net_paid
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year,
           i.i_category,
           -cr.cr_refunded_cash
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year,
           i.i_category,
           -sr.sr_refunded_cash
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year,
           i.i_category,
           -wr.wr_refunded_cash
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
)
SELECT d_year,
       i_category,
       sum(amount) AS net_revenue
FROM data
WHERE d_year BETWEEN 1998 AND 2002
GROUP BY d_year, i_category
ORDER BY d_year, net_revenue DESC
LIMIT 100
