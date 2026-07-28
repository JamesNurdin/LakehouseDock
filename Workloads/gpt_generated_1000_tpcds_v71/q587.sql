/*
Goal: Compare the total return amount and net loss for refunded customers (married with at least two college‑educated dependents) versus returning customers (single with exactly one dependent) broken down by gender. The query also shows a loss‑category flag, the overall return amount across all web returns, and orders the results by gender, marital status and total return amount.
*/
SELECT
    gender,
    marital_status,
    total_return_amount,
    total_net_loss,
    loss_category,
    overall_return_amount
FROM (
    /* Refunded customers (joined via wr_refunded_cdemo_sk) */
    SELECT
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        CASE WHEN SUM(wr.wr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
        (SELECT SUM(wr_all.wr_return_amt) FROM web_returns wr_all) AS overall_return_amount
    FROM web_returns wr
    JOIN customer_demographics cd
      ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M'               -- married
      AND cd.cd_dep_college_count >= 2
      AND EXISTS (
            SELECT 1
            FROM web_returns wr2
            WHERE wr2.wr_order_number = wr.wr_order_number
              AND wr2.wr_return_amt > 50
          )
    GROUP BY cd.cd_gender, cd.cd_marital_status

    UNION ALL

    /* Returning customers (joined via wr_returning_cdemo_sk) */
    SELECT
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        CASE WHEN SUM(wr.wr_net_loss) > 500 THEN 'High' ELSE 'Low' END AS loss_category,
        (SELECT SUM(wr_all.wr_return_amt) FROM web_returns wr_all) AS overall_return_amount
    FROM web_returns wr
    JOIN customer_demographics cd
      ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'S'               -- single
      AND cd.cd_dep_count = 1
      AND wr.wr_return_quantity > 1
    GROUP BY cd.cd_gender, cd.cd_marital_status
) AS combined
ORDER BY gender,
         marital_status,
         total_return_amount DESC
