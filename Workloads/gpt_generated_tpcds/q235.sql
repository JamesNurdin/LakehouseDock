WITH sales AS (
    SELECT
        cs_call_center_sk,
        cs_order_number,
        cs_item_sk,
        cs_net_profit,
        cs_quantity
    FROM catalog_sales
),
returns_agg AS (
    SELECT
        cr_call_center_sk,
        cr_order_number,
        cr_item_sk,
        SUM(cr_net_loss) AS total_return_loss,
        SUM(cr_return_quantity) AS total_return_quantity
    FROM catalog_returns
    GROUP BY cr_call_center_sk, cr_order_number, cr_item_sk
),
agg AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_state,
        SUM(s.cs_net_profit) AS total_sales_profit,
        SUM(COALESCE(r.total_return_loss, 0)) AS total_return_loss,
        SUM(s.cs_quantity) AS total_quantity_sold,
        SUM(COALESCE(r.total_return_quantity, 0)) AS total_quantity_returned
    FROM call_center cc
    JOIN sales s ON s.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN returns_agg r ON r.cr_call_center_sk = cc.cc_call_center_sk
        AND r.cr_order_number = s.cs_order_number
        AND r.cr_item_sk = s.cs_item_sk
    WHERE cc.cc_state = 'CA'
    GROUP BY cc.cc_call_center_id, cc.cc_name, cc.cc_state
)
SELECT
    cc_call_center_id,
    cc_name,
    cc_state,
    total_sales_profit,
    total_return_loss,
    total_sales_profit - total_return_loss AS net_profit_after_returns,
    total_quantity_sold,
    total_quantity_returned,
    CASE WHEN total_quantity_sold > 0
        THEN CAST(total_quantity_returned AS double) / total_quantity_sold
        ELSE 0
    END AS return_rate,
    ROW_NUMBER() OVER (ORDER BY total_sales_profit - total_return_loss DESC) AS profit_rank
FROM agg
ORDER BY net_profit_after_returns DESC
LIMIT 10
