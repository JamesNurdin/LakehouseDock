WITH sales_returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_item_sk,
        cr.cr_return_amount,
        cr.cr_fee,
        cr.cr_return_quantity,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        i.i_item_id,
        i.i_current_price,
        sm.sm_carrier,
        sm.sm_ship_mode_id
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cr.cr_return_amount > 20.0
      AND cr.cr_fee < 80.0
      AND cs.cs_quantity >= 2
      AND cs.cs_net_profit > 0
      AND cd.cd_purchase_estimate BETWEEN 2000 AND 6000
      AND sm.sm_carrier = 'USPS'
      AND i.i_current_price > (
          SELECT avg(i2.i_current_price)
          FROM item i2
          WHERE i2.i_category = 'Electronics'
      )
),
agg AS (
    SELECT
        i_item_id,
        sm_ship_mode_id,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cs_net_paid) AS total_sales_paid,
        COUNT(*) AS txn_count,
        AVG(cs_net_profit) AS avg_profit
    FROM sales_returns
    GROUP BY i_item_id, sm_ship_mode_id
    HAVING SUM(cr_return_amount) > 100
)
SELECT
    i_item_id,
    sm_ship_mode_id,
    total_return_amount,
    total_sales_paid,
    txn_count,
    avg_profit,
    (total_return_amount / NULLIF(total_sales_paid, 0)) AS return_to_sales_ratio
FROM agg
WHERE avg_profit > 5.0
ORDER BY return_to_sales_ratio DESC
LIMIT 100
