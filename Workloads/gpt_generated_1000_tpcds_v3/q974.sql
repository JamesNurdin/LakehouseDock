WITH sales_filtered AS (
    SELECT
        s.cs_order_number,
        s.cs_item_sk,
        s.cs_quantity,
        s.cs_net_paid_inc_ship,
        s.cs_ship_hdemo_sk,
        s.cs_sold_date_sk,
        d_s.d_year,
        d_s.d_month_seq,
        d_s.d_week_seq
    FROM catalog_sales s
    JOIN date_dim d_s
        ON s.cs_sold_date_sk = d_s.d_date_sk
    WHERE d_s.d_year = 2001
      AND d_s.d_week_seq IN (2, 7, 9)
      AND s.cs_net_paid_inc_ship > 1000
      AND s.cs_ship_hdemo_sk IN (4563, 6421)
      AND s.cs_quantity >= 2
      AND d_s.d_holiday = 'N'
), latest_returns AS (
    SELECT
        r.cr_order_number,
        r.cr_item_sk,
        r.cr_store_credit,
        d_r.d_date AS return_date,
        r.cr_returned_date_sk,
        ROW_NUMBER() OVER (PARTITION BY r.cr_order_number, r.cr_item_sk ORDER BY r.cr_returned_date_sk DESC) AS rn
    FROM catalog_returns r
    JOIN date_dim d_r
        ON r.cr_returned_date_sk = d_r.d_date_sk
)
SELECT
    sf.cs_order_number,
    sf.cs_item_sk,
    sf.cs_quantity,
    sf.cs_net_paid_inc_ship,
    sf.d_year,
    sf.d_month_seq,
    sf.d_week_seq,
    lr.return_date,
    lr.cr_store_credit,
    CASE
        WHEN lr.cr_store_credit > 100 THEN 'HIGH_CREDIT'
        WHEN lr.cr_store_credit > 0 THEN 'LOW_CREDIT'
        ELSE 'NO_CREDIT'
    END AS credit_category,
    ROW_NUMBER() OVER (PARTITION BY sf.d_year ORDER BY sf.cs_net_paid_inc_ship DESC) AS rn_year,
    RANK() OVER (PARTITION BY sf.d_year, sf.d_month_seq ORDER BY sf.cs_net_paid_inc_ship DESC) AS rank_month,
    SUM(sf.cs_net_paid_inc_ship) OVER (PARTITION BY sf.d_year ORDER BY sf.cs_sold_date_sk ROWS BETWEEN 3 PRECEDING AND CURRENT ROW) AS moving_sum_4_sales
FROM sales_filtered sf
LEFT JOIN (
    SELECT cr_order_number, cr_item_sk, cr_store_credit, return_date
    FROM latest_returns
    WHERE rn = 1
) lr
    ON lr.cr_order_number = sf.cs_order_number
   AND lr.cr_item_sk = sf.cs_item_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns r2
    WHERE r2.cr_order_number = sf.cs_order_number
      AND r2.cr_item_sk = sf.cs_item_sk
      AND r2.cr_store_credit < 200
      AND r2.cr_reversed_charge BETWEEN 10 AND 50
)
  AND lr.return_date IS NOT NULL
  AND sf.cs_ship_hdemo_sk NOT IN (9999)
ORDER BY sf.cs_net_paid_inc_ship DESC
LIMIT 100
