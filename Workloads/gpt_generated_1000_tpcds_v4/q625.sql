/*
  Goal: Analyze how customer demographics, sales, and returns interact, focusing on specific reasons, high‑cost items, and sizable returns. The query joins the five TPC‑DS tables in a left‑deep chain, applies realistic selective filters, aggregates key financial metrics, classifies gender, and ranks the results by total net loss.
*/
WITH filtered AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_ext_sales_price,
        ss.ss_ext_wholesale_cost,
        cr.cr_return_amount,
        cr.cr_net_loss AS cr_net_loss,
        cr.cr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss AS wr_net_loss,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        r.r_reason_id,
        r.r_reason_desc
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_returns cr
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN web_returns wr
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN reason r
        ON r.r_reason_sk = wr.wr_reason_sk
    WHERE r.r_reason_id IN ('AAAAAAAADAAAAAAA', 'AAAAAAAAMAAAAAAA')
      AND ss.ss_ext_wholesale_cost > 1000
      AND cr.cr_return_quantity >= 2
      AND wr.wr_return_amt_inc_tax BETWEEN 800 AND 1200
)
SELECT
    CASE WHEN cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS gender_label,
    cd_marital_status,
    cd_education_status,
    COUNT(DISTINCT ss_ticket_number) AS orders_sold,
    SUM(ss_ext_sales_price) AS total_store_sales,
    SUM(cr_return_amount) AS total_catalog_return,
    SUM(wr_return_amt) AS total_web_return,
    SUM(cr_net_loss + wr_net_loss) AS total_net_loss,
    AVG(CASE WHEN r_reason_desc LIKE '%price%' THEN cr_return_amount END) AS avg_return_amount_price_reason
FROM filtered
GROUP BY
    CASE WHEN cd_gender = 'M' THEN 'Male' ELSE 'Female' END,
    cd_marital_status,
    cd_education_status
ORDER BY total_net_loss DESC
LIMIT 100
