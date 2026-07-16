WITH sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_ship_mode_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_sold_date_sk
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2451545 AND 2451910
),
ret AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_ship_mode_sk,
        cr.cr_returned_date_sk
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk BETWEEN 2451545 AND 2451910
)
SELECT
    sm.sm_type AS ship_mode,
    cd.cd_gender AS gender,
    SUM(s.cs_net_profit) AS total_net_profit,
    SUM(r.cr_return_amount) AS total_return_amount,
    SUM(r.cr_net_loss) AS total_return_loss,
    (SUM(s.cs_net_profit) - SUM(r.cr_return_amount) - SUM(r.cr_net_loss)) AS net_profit_after_returns,
    RANK() OVER (ORDER BY (SUM(s.cs_net_profit) - SUM(r.cr_return_amount) - SUM(r.cr_net_loss)) DESC) AS profit_rank
FROM sales s
JOIN ret r
    ON s.cs_order_number = r.cr_order_number
JOIN ship_mode sm
    ON r.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd
    ON s.cs_ship_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_gender = 'M'
GROUP BY sm.sm_type, cd.cd_gender
ORDER BY net_profit_after_returns DESC
LIMIT 20
