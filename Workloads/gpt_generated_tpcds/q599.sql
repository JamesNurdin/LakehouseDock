WITH profit_by_category AS (
    SELECT
        i.i_category,
        sm.sm_type,
        cd_bill.cd_gender AS bill_gender,
        cd_refunded.cd_gender AS refunded_gender,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(DISTINCT cs.cs_order_number) AS order_count,
        COUNT(DISTINCT cr.cr_order_number) AS return_count
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_refunded
        ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    WHERE cs.cs_quantity > 0
    GROUP BY i.i_category, sm.sm_type, cd_bill.cd_gender, cd_refunded.cd_gender
)
SELECT
    i_category,
    sm_type,
    bill_gender,
    refunded_gender,
    total_net_profit,
    total_return_amount,
    total_net_loss,
    order_count,
    return_count,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM profit_by_category
ORDER BY profit_rank
LIMIT 10
