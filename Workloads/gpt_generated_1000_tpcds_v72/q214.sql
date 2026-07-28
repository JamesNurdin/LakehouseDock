WITH refunded_returns AS (
    SELECT
        cr_refunded_cdemo_sk AS cd_demo_sk,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns
    WHERE cr_return_amount > 100.00                      -- filter on return amount
      AND cr_net_loss BETWEEN 50.00 AND 2000.00          -- filter on net loss range
      AND cr_return_quantity >= 1                       -- at least one item returned
    GROUP BY cr_refunded_cdemo_sk
)
SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_dep_count,
    SUM(fr.total_return_amount) AS sum_return_amount,
    AVG(ws.ws_net_paid_inc_ship) AS avg_net_paid_inc_ship,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    MIN(ws.ws_list_price) AS min_list_price,
    MAX(ws.ws_list_price) AS max_list_price
FROM refunded_returns fr
JOIN customer_demographics cd
  ON fr.cd_demo_sk = cd.cd_demo_sk
JOIN web_sales ws
  ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_education_status IN ('4 yr Degree', 'College')   -- education filter
  AND cd.cd_dep_count >= 2                                   -- dependent count filter
  AND cd.cd_dep_college_count <= 3                           -- college‑educated dependents filter
  AND ws.ws_net_paid_inc_ship > 500.00                       -- sales revenue filter
  AND ws.ws_list_price BETWEEN 20.00 AND 250.00              -- price range filter
  AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100        -- surrogate date key range filter
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_refunded_cdemo_sk = cd.cd_demo_sk
          AND cr2.cr_return_amount > 2000.00               -- anti‑join: exclude demographics with very large returns
    )
GROUP BY cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_dep_count
ORDER BY sum_return_amount DESC
LIMIT 100
