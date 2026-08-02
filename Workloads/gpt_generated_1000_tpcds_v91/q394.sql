WITH returns_excluding_sales AS (
    SELECT cr_order_number
    FROM catalog_returns
    EXCEPT
    SELECT ws_order_number
    FROM web_sales
),
base AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_order_number,
        i.i_item_sk,
        i.i_brand,
        i.i_category,
        i.i_current_price,
        p.p_promo_id,
        p.p_discount_active,
        ws.ws_net_paid,
        ws.ws_net_profit,
        r.r_reason_desc,
        sm.sm_type,
        wh.w_warehouse_name,
        cd.cd_gender,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ws_site.web_name AS web_site_name,
        (
            SELECT COUNT(*)
            FROM promotion p2
            WHERE p2.p_item_sk = i.i_item_sk
        ) AS total_promos_for_item
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN promotion p ON i.i_item_sk = p.p_item_sk
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    CROSS JOIN LATERAL (
        SELECT *
        FROM web_site ws_s
        WHERE ws_s.web_site_sk = ws.ws_web_site_sk
    ) ws_site
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse wh ON cr.cr_warehouse_sk = wh.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2452390 AND 2452395
      AND i.i_current_price > 100
      AND p.p_discount_active = 'Y'
      AND ws.ws_net_profit > 0
      AND ib.ib_upper_bound >= 100000
      AND sm.sm_type = 'AIR'
      AND EXISTS (
          SELECT 1
          FROM promotion p3
          WHERE p3.p_item_sk = i.i_item_sk
            AND p3.p_cost < 10
      )
      AND cr.cr_order_number IN (SELECT cr_order_number FROM returns_excluding_sales)
)
SELECT
    br.cr_order_number,
    br.cr_returned_date_sk,
    br.r_reason_desc,
    br.i_brand,
    br.i_category,
    br.i_current_price,
    br.ws_net_profit,
    br.total_promos_for_item,
    br.web_site_name,
    CASE WHEN br.i_current_price >= 200 THEN 'EXPENSIVE' ELSE 'AFFORDABLE' END AS price_category,
    RANK() OVER (PARTITION BY br.i_brand ORDER BY br.ws_net_profit DESC) AS brand_profit_rank,
    ROW_NUMBER() OVER (ORDER BY br.cr_return_amount DESC) AS overall_return_amount_rn
FROM base br
ORDER BY brand_profit_rank, br.cr_return_amount DESC
LIMIT 100
