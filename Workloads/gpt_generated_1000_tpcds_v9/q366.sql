WITH base AS (
    SELECT
        cs.cs_ship_date_sk,
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_net_paid,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        wr.wr_return_amt,
        wr.wr_net_loss,
        r.r_reason_sk,
        r.r_reason_desc
    FROM catalog_sales cs
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_returns wr
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
        AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
)
SELECT
    ca_state AS state,
    cd_gender AS gender,
    hd_income_band_sk AS income_band,
    r_reason_desc AS return_reason,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    SUM(cs_ext_sales_price) AS total_sales_amount,
    SUM(cs_net_paid) AS total_sales_net,
    SUM(wr_return_amt) AS total_return_amount,
    SUM(wr_net_loss) AS total_return_loss,
    (SUM(cs_net_paid) - SUM(wr_return_amt)) AS net_revenue
FROM base
WHERE cs_ship_date_sk BETWEEN 2450822 AND 2450904
    AND cd_purchase_estimate >= 5000
    AND cd_gender = 'M'
    AND ca_state = 'CA'
    AND r_reason_sk IN (3, 7, 13)
GROUP BY
    ca_state,
    cd_gender,
    hd_income_band_sk,
    r_reason_desc
ORDER BY net_revenue DESC
LIMIT 100
