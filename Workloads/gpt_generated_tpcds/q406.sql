WITH sales_returns AS (
    SELECT
        cc.cc_call_center_id,
        sd.d_year,
        sd.d_month_seq,
        cs.cs_net_profit,
        cr.cr_net_loss,
        cs.cs_order_number,
        cr.cr_order_number
    FROM catalog_sales cs
    JOIN date_dim sd
        ON cs.cs_sold_date_sk = sd.d_date_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN date_dim rd
        ON cr.cr_returned_date_sk = rd.d_date_sk
    WHERE sd.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
)
SELECT
    cc_call_center_id,
    d_year,
    d_month_seq,
    sum(cs_net_profit) AS total_sales_profit,
    sum(cr_net_loss) AS total_return_loss,
    sum(cs_net_profit) - coalesce(sum(cr_net_loss), 0) AS net_profit_adjusted,
    count(DISTINCT cs_order_number) AS orders_count,
    count(cr_order_number) AS returns_count
FROM sales_returns
GROUP BY cc_call_center_id, d_year, d_month_seq
ORDER BY net_profit_adjusted DESC
LIMIT 100
