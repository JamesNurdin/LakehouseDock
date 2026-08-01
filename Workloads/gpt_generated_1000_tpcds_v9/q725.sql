WITH filtered_sales_and_returns AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_net_profit,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_fee,
        sr.sr_net_loss,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_dep_count,
        cd.cd_dep_college_count
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
       AND cs.cs_item_sk = cr.cr_item_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN store_returns sr
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE cs.cs_wholesale_cost > 30.0
      AND cs.cs_quantity >= 2
      AND cr.cr_return_quantity > 0
      AND sr.sr_fee > 10.0
)
SELECT
    cd_gender,
    cd_marital_status,
    cd_dep_count,
    cd_dep_college_count,
    SUM(cs_net_paid_inc_ship_tax) AS total_sales,
    SUM(cs_net_profit) AS total_profit,
    SUM(cr_net_loss + sr_net_loss) AS total_return_loss,
    (SUM(cs_net_profit) - SUM(cr_net_loss + sr_net_loss)) AS net_contribution,
    RANK() OVER (ORDER BY (SUM(cs_net_profit) - SUM(cr_net_loss + sr_net_loss)) DESC) AS profit_rank,
    (SELECT AVG(cs3.cs_net_profit) FROM catalog_sales cs3) AS overall_avg_profit
FROM filtered_sales_and_returns
GROUP BY
    cd_gender,
    cd_marital_status,
    cd_dep_count,
    cd_dep_college_count
HAVING SUM(cs_net_profit) > 500
ORDER BY net_contribution DESC
LIMIT 100
