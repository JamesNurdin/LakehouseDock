WITH base AS (
    SELECT
        td.t_hour,
        cd.cd_gender,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cr.cr_net_loss) AS total_loss,
        COUNT(DISTINCT cs.cs_order_number) AS orders,
        SUM(cs.cs_ext_sales_price) AS sales_amount
    FROM catalog_sales cs
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    WHERE td.t_hour BETWEEN 8 AND 20
      AND cd.cd_gender = 'F'
      AND cs.cs_quantity > 1
    GROUP BY td.t_hour, cd.cd_gender
)
SELECT
    base.t_hour,
    base.cd_gender,
    base.total_profit,
    base.total_loss,
    base.orders,
    base.sales_amount,
    (base.total_profit - base.total_loss) AS net_contribution,
    SUM(base.total_profit) OVER (PARTITION BY base.cd_gender ORDER BY base.t_hour) AS cumulative_profit_by_gender,
    RANK() OVER (ORDER BY (base.total_profit - base.total_loss) DESC) AS profit_rank
FROM base
ORDER BY net_contribution DESC
LIMIT 100
