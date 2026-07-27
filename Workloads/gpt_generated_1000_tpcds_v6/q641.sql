WITH cs_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_ship_mode_sk,
        cs.cs_sold_time_sk,
        SUM(cs.cs_quantity) AS cs_total_qty,
        SUM(cs.cs_net_paid) AS cs_total_paid
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 5
      AND cs.cs_net_paid > 100
    GROUP BY cs.cs_item_sk, cs.cs_promo_sk, cs.cs_ship_mode_sk, cs.cs_sold_time_sk
),
ws_agg AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_promo_sk,
        ws.ws_ship_mode_sk,
        ws.ws_sold_time_sk,
        SUM(ws.ws_quantity) AS ws_total_qty,
        SUM(ws.ws_net_paid) AS ws_total_paid
    FROM web_sales ws
    WHERE ws.ws_quantity > 0
      AND ws.ws_net_paid > 50
    GROUP BY ws.ws_item_sk, ws.ws_promo_sk, ws.ws_ship_mode_sk, ws.ws_sold_time_sk
),
joined AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_ship_mode_sk,
        cs.cs_sold_time_sk,
        cs.cs_total_qty,
        cs.cs_total_paid,
        ws.ws_total_qty,
        ws.ws_total_paid
    FROM cs_agg cs
    JOIN ws_agg ws
        ON cs.cs_item_sk = ws.ws_item_sk
       AND cs.cs_promo_sk = ws.ws_promo_sk
       AND cs.cs_ship_mode_sk = ws.ws_ship_mode_sk
       AND cs.cs_sold_time_sk = ws.ws_sold_time_sk
)
SELECT
    i.i_category,
    i.i_brand,
    p.p_channel_email,
    sm.sm_type,
    td.t_sub_shift,
    j.cs_total_qty,
    j.ws_total_qty,
    (j.cs_total_qty + j.ws_total_qty) AS total_qty,
    (j.cs_total_paid + j.ws_total_paid) AS total_paid,
    SUM(j.cs_total_paid + j.ws_total_paid) OVER (
        PARTITION BY i.i_category
        ORDER BY (j.cs_total_paid + j.ws_total_paid) DESC
    ) AS category_paid_rank
FROM joined j
JOIN item i
    ON j.cs_item_sk = i.i_item_sk
JOIN promotion p
    ON j.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm
    ON j.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim td
    ON j.cs_sold_time_sk = td.t_time_sk
WHERE sm.sm_type = 'OVERNIGHT'
  AND p.p_channel_email = 'Y'
  AND td.t_sub_shift = 'morning'
  AND i.i_category IN (
        SELECT DISTINCT i2.i_category
        FROM item i2
        WHERE i2.i_brand = 'BrandX'
      )
GROUP BY i.i_category, i.i_brand, p.p_channel_email, sm.sm_type, td.t_sub_shift,
         j.cs_total_qty, j.ws_total_qty, j.cs_total_paid, j.ws_total_paid
HAVING SUM(j.cs_total_paid + j.ws_total_paid) > 1000
ORDER BY total_paid DESC
LIMIT 100
