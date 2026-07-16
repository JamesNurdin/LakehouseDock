WITH sales_agg AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_sales,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        SUM(ss.ss_quantity) AS total_sales_qty,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F'
      AND cd.cd_credit_rating = 'Good'
      AND ss.ss_sold_date_sk >= 2450000
    GROUP BY cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
returns_agg AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        SUM(wr.wr_net_loss) AS total_return_loss,
        SUM(wr.wr_return_quantity) AS total_return_qty
    FROM web_returns wr
    JOIN customer_demographics cd
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F'
      AND cd.cd_credit_rating = 'Good'
    GROUP BY cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
)
SELECT
    s.cd_gender,
    s.cd_marital_status,
    s.cd_credit_rating,
    s.num_sales,
    s.total_sales_profit,
    s.total_sales_qty,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    COALESCE(r.total_return_qty, 0) AS total_return_qty,
    (s.total_sales_profit - COALESCE(r.total_return_loss, 0)) AS net_margin,
    s.avg_purchase_estimate,
    RANK() OVER (ORDER BY (s.total_sales_profit - COALESCE(r.total_return_loss, 0)) DESC) AS profit_rank
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.cd_gender = r.cd_gender
   AND s.cd_marital_status = r.cd_marital_status
   AND s.cd_credit_rating = r.cd_credit_rating
WHERE s.num_sales >= 100
ORDER BY net_margin DESC
LIMIT 20
