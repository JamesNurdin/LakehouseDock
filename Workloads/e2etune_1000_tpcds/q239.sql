WITH sales AS (
    SELECT
        i.i_brand AS brand,
        sm.sm_ship_mode_id AS ship_mode_id,
        sm.sm_type AS ship_mode_type,
        SUM(cs.cs_net_paid_inc_tax) AS total_sales_amount,
        SUM(cs.cs_quantity) AS total_sales_quantity,
        SUM(cs.cs_net_profit) AS total_sales_net_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY i.i_brand, sm.sm_ship_mode_id, sm.sm_type
),
returns AS (
    SELECT
        i.i_brand AS brand,
        sm.sm_ship_mode_id AS ship_mode_id,
        SUM(cr.cr_return_amt_inc_tax) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_net_loss) AS total_return_net_loss
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc = 'Damaged'
    GROUP BY i.i_brand, sm.sm_ship_mode_id
)
SELECT
    s.brand,
    s.ship_mode_id,
    s.ship_mode_type,
    s.total_sales_amount,
    s.total_sales_quantity,
    s.total_sales_net_profit,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(r.total_return_net_loss, 0) AS total_return_net_loss,
    s.total_sales_net_profit - COALESCE(r.total_return_net_loss, 0) AS net_profit_after_returns,
    s.avg_discount,
    (COALESCE(r.total_return_quantity, 0) / NULLIF(s.total_sales_quantity, 0)) AS return_rate,
    RANK() OVER (ORDER BY (s.total_sales_net_profit - COALESCE(r.total_return_net_loss, 0)) DESC) AS profit_rank
FROM sales s
LEFT JOIN returns r
    ON s.brand = r.brand
   AND s.ship_mode_id = r.ship_mode_id
WHERE s.ship_mode_type = 'AIR'
  AND s.total_sales_quantity > 100
ORDER BY net_profit_after_returns DESC
LIMIT 10
