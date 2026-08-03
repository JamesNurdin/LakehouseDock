/* Goal: Analyze the combined impact of product returns and web sales for high‑value customers in a specific fiscal year and week, summarizing return amounts, net profit, and tax behavior */
WITH filtered_date AS (
    SELECT d_date_sk, d_year, d_fy_year, d_week_seq
    FROM date_dim
    WHERE d_fy_year = 1916
      AND d_week_seq = 15
),
filtered_cd AS (
    SELECT cd_demo_sk, cd_gender, cd_marital_status, cd_purchase_estimate
    FROM customer_demographics
    WHERE cd_purchase_estimate >= 5000
),
filtered_ws AS (
    SELECT ws_sold_date_sk,
           ws_bill_cdemo_sk,
           ws_quantity,
           ws_ext_sales_price,
           ws_net_profit,
           ws_order_number
    FROM web_sales
    WHERE ws_quantity > 2
      AND ws_ext_sales_price > 100
)
SELECT
    d.d_year,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(ws.ws_net_profit) AS avg_net_profit,
    COUNT(DISTINCT cr.cr_order_number) AS cnt_return_orders,
    SUM(CASE WHEN cr.cr_return_tax > 1.0 THEN cr.cr_return_tax ELSE 0 END) AS tax_over_1_sum
FROM catalog_returns cr
JOIN filtered_date d
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN filtered_cd cd
  ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN filtered_ws ws
  ON ws.ws_sold_date_sk = d.d_date_sk
  AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
WHERE cr.cr_fee > 30
GROUP BY d.d_year, cd.cd_gender, cd.cd_marital_status
ORDER BY d.d_year, total_return_amount DESC
LIMIT 100
