/*
  Goal: Identify high‑selling product classes within a specific department, comparing total catalog sales to total store returns and flagging whether the net profit after returns is positive or negative.
*/
WITH sales AS (
    SELECT
        cp.cp_department,
        i.i_class,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_net_paid,
        cs.cs_order_number,
        cs.cs_quantity
    FROM
        catalog_sales cs
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE
        cs.cs_net_paid > 1000
        AND cs.cs_quantity >= 2
        AND cp.cp_department = 'Sports'
        AND i.i_class = 'hockey'
),
returns AS (
    SELECT
        i.i_class,
        sr.sr_return_amt,
        sr.sr_net_loss,
        sr.sr_return_quantity
    FROM
        store_returns sr
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE
        sr.sr_return_quantity <= 20
)
SELECT
    s.cp_department,
    s.i_class,
    SUM(s.cs_ext_sales_price) AS total_sales,
    SUM(r.sr_return_amt) AS total_returns,
    COUNT(DISTINCT s.cs_order_number) AS order_cnt,
    AVG(s.cs_net_paid) AS avg_net_paid,
    CASE
        WHEN SUM(s.cs_net_profit) - SUM(r.sr_net_loss) > 0 THEN 'POS'
        ELSE 'NEG'
    END AS profit_flag
FROM
    sales s
    JOIN returns r ON s.i_class = r.i_class
GROUP BY
    s.cp_department,
    s.i_class
ORDER BY
    total_sales DESC
LIMIT 100
