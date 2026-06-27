WITH sales_returns AS (
    SELECT
        cs.cs_call_center_sk,
        cc.cc_name,
        d.d_year,
        d.d_month_seq,
        hd.hd_buy_potential,
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_net_profit,
        cs.cs_quantity,
        cr.cr_return_quantity,
        cr.cr_net_loss
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
        AND cs.cs_call_center_sk = cr.cr_call_center_sk
    WHERE d.d_date >= DATE '2000-01-01'
      AND d.d_date < DATE '2001-01-01'
)
SELECT
    cc_name,
    hd_buy_potential,
    d_year,
    d_month_seq,
    SUM(cs_net_profit) AS total_sales_profit,
    SUM(COALESCE(cr_net_loss, 0)) AS total_return_loss,
    SUM(cs_net_profit) - SUM(COALESCE(cr_net_loss, 0)) AS net_profit_after_returns,
    COUNT(DISTINCT cs_order_number) AS num_orders,
    SUM(cs_quantity) AS total_quantity_sold,
    SUM(COALESCE(cr_return_quantity, 0)) AS total_quantity_returned
FROM sales_returns
GROUP BY
    cc_name,
    hd_buy_potential,
    d_year,
    d_month_seq
ORDER BY net_profit_after_returns DESC
LIMIT 100
