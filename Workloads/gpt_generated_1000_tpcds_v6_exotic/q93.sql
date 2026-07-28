/* goal: Rank billing customers by total net profit within each department for high‑profit sales and related returns, categorizing profit sign */
WITH base AS (
    SELECT
        cs.cs_bill_customer_sk AS bill_customer_sk,
        cp.cp_department AS cp_department,
        cd_bill.cd_gender AS cd_gender,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(cr.cr_return_amount) AS return_cnt,
        CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'POSITIVE' ELSE 'NEGATIVE' END AS profit_sign
    FROM tpcds.catalog_sales cs
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN tpcds.reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE cs.cs_net_profit > 1000
      AND cs.cs_quantity BETWEEN 1 AND 5
      AND cr.cr_store_credit > 100
      AND r.r_reason_id LIKE 'AAAAAAA%'
      AND cp.cp_department = 'Sports'
      AND wr.wr_return_quantity <= 2
      AND cd_bill.cd_gender = 'M'
    GROUP BY cs.cs_bill_customer_sk, cp.cp_department, cd_bill.cd_gender
)
SELECT
    bill_customer_sk,
    cp_department,
    cd_gender,
    total_net_profit,
    total_return_amount,
    return_cnt,
    profit_sign,
    RANK() OVER (PARTITION BY cp_department ORDER BY total_net_profit DESC) AS dept_profit_rank
FROM base
ORDER BY dept_profit_rank, total_net_profit DESC
LIMIT 100
