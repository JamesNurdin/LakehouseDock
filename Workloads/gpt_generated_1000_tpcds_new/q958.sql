WITH sales_returns AS (
    SELECT
        COALESCE(cs.cs_order_number, cr.cr_order_number) AS order_number,
        d.d_date AS trans_date,
        i.i_item_id AS item_id,
        i.i_category AS category,
        COALESCE(cs.cs_quantity, 0) - COALESCE(cr.cr_return_quantity, 0) AS metric,
        CASE WHEN COALESCE(cs.cs_quantity, 0) > 5 THEN 'Large' ELSE 'Small' END AS flag,
        SUM(COALESCE(cs.cs_net_paid, 0) - COALESCE(cr.cr_return_amount, 0))
            OVER (PARTITION BY i.i_category ORDER BY d.d_date ROWS UNBOUNDED PRECEDING) AS running_total
    FROM catalog_sales cs
    FULL OUTER JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
    JOIN item i
        ON COALESCE(cs.cs_item_sk, cr.cr_item_sk) = i.i_item_sk
    JOIN date_dim d
        ON d.d_date_sk = COALESCE(cs.cs_sold_date_sk, cr.cr_returned_date_sk)
    WHERE d.d_year = 2001
      AND i.i_color IN ('pink', 'turquoise')
),
web_returns_agg AS (
    SELECT
        wr.wr_order_number AS order_number,
        d.d_date AS trans_date,
        i.i_item_id AS item_id,
        i.i_category AS category,
        wr.wr_return_quantity AS metric,
        CASE WHEN wr.wr_return_amt > 100 THEN 'High' ELSE 'Low' END AS flag,
        SUM(wr.wr_return_amt)
            OVER (PARTITION BY i.i_category ORDER BY d.d_date ROWS UNBOUNDED PRECEDING) AS running_total
    FROM web_returns wr
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_color IN ('pink', 'turquoise')
)
SELECT order_number,
       trans_date,
       item_id,
       category,
       metric,
       flag,
       running_total
FROM (
    SELECT order_number, trans_date, item_id, category, metric, flag, running_total
    FROM sales_returns
    UNION
    SELECT order_number, trans_date, item_id, category, metric, flag, running_total
    FROM web_returns_agg
) u
ORDER BY running_total DESC
LIMIT 100
