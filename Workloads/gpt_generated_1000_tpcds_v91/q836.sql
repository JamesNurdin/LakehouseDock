WITH
catalog_agg AS (
    SELECT
        i.i_category,
        w.w_warehouse_name,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(cr.cr_return_tax) AS avg_return_tax
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE cd.cd_purchase_estimate > 3000
      AND cd.cd_dep_employed_count >= 1
      AND w.w_warehouse_sq_ft > 500000
      AND sm.sm_carrier = 'UPS'
      AND i.i_current_price BETWEEN 20 AND 500
      AND cr.cr_return_quantity > 0
    GROUP BY i.i_category, w.w_warehouse_name
),
web_agg AS (
    SELECT
        i.i_category,
        SUM(wr.wr_return_amt) AS total_web_return_amount,
        COUNT(*) AS web_return_cnt,
        AVG(wr.wr_return_tax) AS avg_web_return_tax
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE cd.cd_purchase_estimate > 2000
      AND cd.cd_dep_employed_count >= 2
      AND i.i_current_price BETWEEN 30 AND 300
      AND wr.wr_return_quantity > 0
      AND wr.wr_return_tax > 0
    GROUP BY i.i_category
),
intersected_categories AS (
    SELECT i_category FROM catalog_agg WHERE total_return_amount > 15000
    INTERSECT
    SELECT i_category FROM web_agg WHERE total_web_return_amount > 8000
)
SELECT
    ca.i_category,
    ca.w_warehouse_name,
    ca.total_return_amount,
    ca.total_net_loss,
    ca.return_cnt,
    RANK() OVER (PARTITION BY ca.i_category ORDER BY ca.total_return_amount DESC) AS warehouse_return_rank,
    SUM(ca.total_return_amount) OVER (PARTITION BY ca.i_category) AS category_total_return_amount
FROM catalog_agg ca
WHERE ca.i_category IN (SELECT i_category FROM intersected_categories)
  AND EXISTS (
        SELECT 1
        FROM web_returns wr
        JOIN item i2 ON wr.wr_item_sk = i2.i_item_sk
        WHERE i2.i_category = ca.i_category
          AND wr.wr_return_amt > 100
      )
ORDER BY ca.total_return_amount DESC
LIMIT 100
