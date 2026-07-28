WITH base AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_return_quantity,
        i.i_item_id,
        i.i_category,
        i.i_brand,
        i.i_current_price,
        cp.cp_department,
        sm.sm_carrier,
        cd.cd_gender,
        hd.hd_income_band_sk,
        p.p_promo_name,
        p.p_discount_active
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    JOIN customer cust ON cr.cr_refunded_customer_sk = cust.c_customer_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE cr.cr_return_amount > 0
      AND cr.cr_return_quantity >= 1
      AND i.i_current_price BETWEEN 10 AND 1000
      AND sm.sm_carrier IN ('UPS', 'FEDEX')
      AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2451000
      AND EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_item_sk = i.i_item_sk
            AND wr.wr_return_amt > 50
      )
      AND NOT EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_item_sk = i.i_item_sk
            AND p2.p_discount_active = 'Y'
      )
),
agg_by_item AS (
    SELECT
        i_item_id,
        i_category,
        i_brand,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM base
    GROUP BY i_item_id, i_category, i_brand
)
SELECT
    i_category,
    i_brand,
    SUM(total_return_amount) AS category_brand_return_amount,
    AVG(total_net_loss) AS avg_net_loss_per_item,
    SUM(return_cnt) AS total_returns
FROM agg_by_item
WHERE total_return_amount > 100
  AND return_cnt >= 5
  AND i_category IN (
        SELECT DISTINCT i_category
        FROM item
        WHERE i_color = 'Red'
    )
GROUP BY i_category, i_brand
ORDER BY category_brand_return_amount DESC
LIMIT 100
