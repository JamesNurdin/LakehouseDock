WITH returns_summary AS (
    SELECT
        wr.wr_order_number,
        wr.wr_item_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_return_loss
    FROM web_returns wr
    GROUP BY wr.wr_order_number, wr.wr_item_sk
)
SELECT
    cs.cs_bill_customer_sk,
    d.cd_gender,
    d.cd_marital_status,
    cs.cs_sold_date_sk,
    cs.cs_net_paid,
    COALESCE(r.total_return_loss, 0) AS return_loss,
    SUM(cs.cs_net_paid) OVER (
        PARTITION BY cs.cs_bill_customer_sk
        ORDER BY cs.cs_sold_date_sk
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_net_paid,
    SUM(cs.cs_net_paid - COALESCE(r.total_return_loss, 0)) OVER (
        PARTITION BY cs.cs_bill_customer_sk
        ORDER BY cs.cs_sold_date_sk
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_net_paid_adj,
    ROW_NUMBER() OVER (
        PARTITION BY cs.cs_bill_customer_sk
        ORDER BY cs.cs_sold_date_sk DESC
    ) AS recent_sale_rank,
    CASE
        WHEN d.cd_purchase_estimate >= 10000 THEN 'High Estimate'
        WHEN d.cd_purchase_estimate BETWEEN 5000 AND 9999 THEN 'Medium Estimate'
        ELSE 'Low Estimate'
    END AS purchase_estimate_category,
    sm.sm_type AS shipping_type
FROM catalog_sales cs
JOIN customer_demographics d
    ON cs.cs_bill_cdemo_sk = d.cd_demo_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN returns_summary r
    ON cs.cs_order_number = r.wr_order_number
    AND cs.cs_item_sk = r.wr_item_sk
WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
ORDER BY cs.cs_bill_customer_sk, cs.cs_sold_date_sk
