WITH sales_returns AS (
    SELECT
        d.d_year,
        d.d_moy,
        cc.cc_division_name,
        i.i_category,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        SUM(COALESCE(cr.cr_net_loss, 0)) AS total_return_loss
    FROM
        catalog_sales cs
        JOIN date_dim d
            ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN call_center cc
            ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN item i
            ON cs.cs_item_sk = i.i_item_sk
        LEFT JOIN catalog_returns cr
            ON cs.cs_order_number = cr.cr_order_number
            AND cs.cs_item_sk = cr.cr_item_sk
    WHERE
        d.d_date >= DATE '2001-01-01'
        AND d.d_date < DATE '2002-01-01'
    GROUP BY
        d.d_year,
        d.d_moy,
        cc.cc_division_name,
        i.i_category
)
SELECT
    d_year,
    d_moy,
    cc_division_name,
    i_category,
    total_sales_profit - total_return_loss AS net_profit
FROM
    sales_returns
ORDER BY
    net_profit DESC
LIMIT 20
