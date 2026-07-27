WITH sales_returns_agg AS (
    SELECT
        cc.cc_call_center_id AS cc_id,
        d_sold.d_year AS sales_year,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS orders_sold,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        AVG(cs.cs_net_paid_inc_ship) AS avg_paid_inc_ship
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    WHERE d_sold.d_year = 2001
      AND d_sold.d_month_seq BETWEEN 1 AND 12
      AND cc.cc_manager = 'Alden Snyder'
      AND cc.cc_mkt_id IN (1, 2, 3)
      AND cs.cs_net_paid_inc_ship > 1000
      AND cr.cr_return_quantity > 0
    GROUP BY cc.cc_call_center_id, d_sold.d_year
)
SELECT
    agg.cc_id,
    agg.sales_year,
    agg.total_net_profit,
    agg.orders_sold,
    CASE
        WHEN agg.total_return_qty > 10 THEN 'High Returns'
        ELSE 'Low Returns'
    END AS return_level,
    (SELECT AVG(total_net_profit) FROM sales_returns_agg) AS avg_profit_all_centers
FROM sales_returns_agg agg
WHERE agg.total_net_profit > (SELECT AVG(total_net_profit) FROM sales_returns_agg)
ORDER BY agg.total_net_profit DESC
LIMIT 100
