WITH inv_agg AS (
    SELECT inv_item_sk,
           inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_item_sk, inv_warehouse_sk
),
cr_agg AS (
    SELECT cr_item_sk,
           cr_warehouse_sk,
           SUM(cr_return_amount) AS total_return_amount,
           SUM(cr_return_quantity) AS total_return_qty,
           MIN(cr_refunded_hdemo_sk) AS refunded_hdemo_sk
    FROM catalog_returns
    WHERE cr_returned_date_sk BETWEEN 2450000 AND 2453650
      AND cr_return_amount > 10
      AND cr_return_quantity > 0
    GROUP BY cr_item_sk, cr_warehouse_sk
),
wr_agg AS (
    SELECT wr_item_sk,
           SUM(wr_return_amt) AS web_return_amount,
           SUM(wr_return_quantity) AS web_return_qty
    FROM web_returns
    WHERE wr_returned_date_sk BETWEEN 2450000 AND 2453650
      AND wr_return_amt > 5
    GROUP BY wr_item_sk
)
SELECT
    w.w_warehouse_name,
    i.i_item_id,
    i.i_product_name,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    p.p_promo_name,
    cd.cd_gender,
    SUM(inv_agg.total_qty_on_hand)                         AS total_stock_qty,
    SUM(cr_agg.total_return_amount)                       AS total_return_amount,
    SUM(wr_agg.web_return_amount)                         AS total_web_return_amount,
    SUM(cr_agg.total_return_amount - COALESCE(wr_agg.web_return_amount, 0)) AS net_return_amount,
    (SELECT COUNT(*) FROM promotion WHERE p_discount_active = 'Y') AS active_promo_cnt
FROM cr_agg
JOIN inv_agg
  ON cr_agg.cr_item_sk = inv_agg.inv_item_sk
 AND cr_agg.cr_warehouse_sk = inv_agg.inv_warehouse_sk
JOIN item i
  ON cr_agg.cr_item_sk = i.i_item_sk
JOIN warehouse w
  ON cr_agg.cr_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
  ON p.p_item_sk = i.i_item_sk
JOIN customer_demographics cd
  ON EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_item_sk = cr_agg.cr_item_sk
          AND cr.cr_returning_cdemo_sk = cd.cd_demo_sk
        LIMIT 1
      )
JOIN household_demographics hd
  ON hd.hd_demo_sk = cr_agg.refunded_hdemo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN wr_agg
  ON wr_agg.wr_item_sk = i.i_item_sk
WHERE p.p_discount_active = 'Y'
  AND hd.hd_buy_potential = '>10000'
  AND cd.cd_gender = 'M'
  AND w.w_state = 'CA'
GROUP BY
    w.w_warehouse_name,
    i.i_item_id,
    i.i_product_name,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    p.p_promo_name,
    cd.cd_gender
HAVING SUM(cr_agg.total_return_amount - COALESCE(wr_agg.web_return_amount, 0)) > (
        SELECT AVG(total_return_amount - web_return_amount)
        FROM (
            SELECT cr_agg2.total_return_amount,
                   COALESCE(wr_agg2.web_return_amount, 0) AS web_return_amount
            FROM cr_agg AS cr_agg2
            LEFT JOIN wr_agg AS wr_agg2 ON wr_agg2.wr_item_sk = cr_agg2.cr_item_sk
        ) sub
      )
ORDER BY net_return_amount DESC
LIMIT 100
