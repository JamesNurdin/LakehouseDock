/*
Goal: Identify the top return reasons (by total return amount) for high‑priced items returned by male customers with excellent credit, shipped via UPS, where the reason contains the word 'defect'. The query aggregates return data, filters with several predicates (including an EXISTS subquery), computes a window rank, and adds a scalar subquery for the maximum price of a specific brand.
*/
WITH return_stats AS (
    SELECT
        r.r_reason_desc,
        sm.sm_carrier,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_net_loss) AS avg_net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE i.i_current_price > 100
      AND cd.cd_gender = 'M'
      AND cd.cd_credit_rating = 'Excellent'
      AND sm.sm_carrier = 'UPS'
      AND r.r_reason_desc LIKE '%defect%'
      AND EXISTS (
          SELECT 1
          FROM store_sales ss2
          WHERE ss2.ss_item_sk = i.i_item_sk
            AND ss2.ss_net_profit > 500
      )
    GROUP BY r.r_reason_desc, sm.sm_carrier
)
SELECT
    rs.r_reason_desc,
    rs.sm_carrier,
    rs.total_return_amount,
    rs.avg_net_loss,
    rs.return_cnt,
    ROW_NUMBER() OVER (PARTITION BY rs.r_reason_desc ORDER BY rs.total_return_amount DESC) AS reason_rank,
    (SELECT MAX(i2.i_current_price) FROM item i2 WHERE i2.i_brand = 'Brand#12') AS max_brand12_price
FROM return_stats rs
WHERE rs.return_cnt > 10
  AND rs.total_return_amount > (
        SELECT AVG(cr2.cr_return_amount)
        FROM catalog_returns cr2
    )
ORDER BY rs.total_return_amount DESC
LIMIT 10
