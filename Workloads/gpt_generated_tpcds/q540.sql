WITH sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_catalog_page_sk,
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_net_profit,
        cp.cp_department
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
),
returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_item_sk,
        cr.cr_order_number,
        cr.cr_net_loss
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
)
SELECT
    s.cp_department,
    CONCAT(CAST(d_sales.d_year AS varchar), '-', LPAD(CAST(d_sales.d_moy AS varchar), 2, '0')) AS month,
    SUM(s.cs_net_profit) AS total_sales_net_profit,
    COALESCE(SUM(r.cr_net_loss), 0) AS total_returns_net_loss,
    SUM(s.cs_net_profit) - COALESCE(SUM(r.cr_net_loss), 0) AS net_profit_after_returns
FROM sales s
LEFT JOIN returns r
    ON s.cs_item_sk = r.cr_item_sk
    AND s.cs_order_number = r.cr_order_number
JOIN date_dim d_sales
    ON s.cs_sold_date_sk = d_sales.d_date_sk
GROUP BY
    s.cp_department,
    CONCAT(CAST(d_sales.d_year AS varchar), '-', LPAD(CAST(d_sales.d_moy AS varchar), 2, '0'))
ORDER BY
    s.cp_department,
    month
