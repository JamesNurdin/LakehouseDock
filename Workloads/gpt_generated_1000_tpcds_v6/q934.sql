WITH cs_agg AS (
    SELECT
        cs.cs_item_sk,
        SUM(cs.cs_ext_sales_price)            AS catalog_sales_amt,
        MAX(cs.cs_ship_mode_sk)                AS ship_mode_sk,
        MAX(cs.cs_promo_sk)                    AS promo_sk,
        MAX(cs.cs_bill_cdemo_sk)               AS bill_cdemo_sk,
        SUM(cs.cs_quantity)                    AS total_quantity,
        SUM(cs.cs_ext_discount_amt)            AS total_discount
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 1
      AND cs.cs_ext_discount_amt < 1000
    GROUP BY cs.cs_item_sk
),
ws_agg AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_ext_sales_price)            AS web_sales_amt,
        SUM(ws.ws_quantity)                    AS total_ws_quantity,
        SUM(ws.ws_ext_discount_amt)            AS total_ws_discount
    FROM web_sales ws
    WHERE ws.ws_quantity > 1
      AND ws.ws_ext_discount_amt < 1000
    GROUP BY ws.ws_item_sk
)
SELECT
    i.i_item_id,
    i.i_category,
    i.i_category_id,
    p.p_promo_name,
    sm.sm_carrier,
    cd.cd_credit_rating,
    cs_agg.catalog_sales_amt,
    ws_agg.web_sales_amt,
    RANK() OVER (PARTITION BY i.i_category ORDER BY (cs_agg.catalog_sales_amt + ws_agg.web_sales_amt) DESC) AS category_rank,
    CASE
        WHEN cd.cd_credit_rating = 'Good' THEN 'High Credit'
        ELSE 'Other Credit'
    END AS credit_group
FROM cs_agg
JOIN ws_agg
    ON cs_agg.cs_item_sk = ws_agg.ws_item_sk
JOIN item i
    ON i.i_item_sk = cs_agg.cs_item_sk
JOIN promotion p
    ON p.p_promo_sk = cs_agg.promo_sk
JOIN ship_mode sm
    ON sm.sm_ship_mode_sk = cs_agg.ship_mode_sk
JOIN customer_demographics cd
    ON cd.cd_demo_sk = cs_agg.bill_cdemo_sk
WHERE i.i_category_id BETWEEN 2 AND 6
  AND i.i_rec_start_date >= DATE '2000-01-01'
  AND p.p_channel_dmail = 'Y'
  AND sm.sm_type = 'AIR'
  AND EXISTS (
        SELECT 1
        FROM promotion p_sub
        WHERE p_sub.p_promo_sk = cs_agg.promo_sk
          AND p_sub.p_channel_email = 'Y'
    )
ORDER BY category_rank
LIMIT 100
