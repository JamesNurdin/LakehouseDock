WITH returns_agg AS (
    SELECT
        cr.cr_order_number,
        cr.cr_item_sk,
        SUM(cr.cr_net_loss) AS return_loss
    FROM
        catalog_returns cr
    GROUP BY
        cr.cr_order_number,
        cr.cr_item_sk
)
SELECT
    d.d_year,
    i.i_category,
    cc.cc_name,
    SUM(cs.cs_net_profit) AS total_sales_profit,
    COALESCE(SUM(r.return_loss), 0) AS total_return_loss,
    SUM(cs.cs_net_profit) - COALESCE(SUM(r.return_loss), 0) AS net_profit_after_returns,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    COUNT(DISTINCT r.cr_order_number) AS distinct_returns
FROM
    catalog_sales cs
JOIN
    date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN
    item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN
    call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN
    returns_agg r
    ON cs.cs_order_number = r.cr_order_number
    AND cs.cs_item_sk = r.cr_item_sk
WHERE
    d.d_year = 2001
GROUP BY
    d.d_year,
    i.i_category,
    cc.cc_name
ORDER BY
    net_profit_after_returns DESC
LIMIT 20
