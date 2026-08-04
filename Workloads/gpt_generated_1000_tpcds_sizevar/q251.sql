WITH returned_items AS (
    SELECT DISTINCT cr.cr_item_sk
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '\\d{3,}')
      AND cr.cr_return_amount > 50
),
sold_items AS (
    SELECT DISTINCT ws.ws_item_sk
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, 'Premium')
      AND ws.ws_net_paid > 1000
),
intersect_items AS (
    SELECT cr_item_sk AS i_item_sk FROM returned_items
    INTERSECT
    SELECT ws_item_sk FROM sold_items
),
promo_items AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_item_desc,
        p.p_promo_name,
        SUM(ws.ws_ext_sales_price)          AS total_sales,
        SUM(ws.ws_net_profit)               AS total_profit,
        SUM(cr.cr_return_amount)            AS total_returns,
        SUM(cr.cr_net_loss)                 AS total_loss
    FROM intersect_items ii
    JOIN item i          ON ii.i_item_sk = i.i_item_sk
    JOIN promotion p     ON p.p_item_sk = i.i_item_sk
    JOIN web_sales ws    ON ws.ws_item_sk = i.i_item_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    WHERE regexp_like(p.p_promo_name, 'SAVE')
      AND EXISTS (
          SELECT 1
          FROM web_sales ws2
          WHERE ws2.ws_item_sk = i.i_item_sk
            AND ws2.ws_net_paid > 1500
      )
    GROUP BY i.i_item_sk, i.i_category, i.i_item_desc, p.p_promo_name
)
SELECT
    pi.i_category,
    pi.i_item_desc,
    CONCAT(SUBSTRING(pi.i_item_desc, 1, 10), '...')               AS short_desc,
    pi.p_promo_name,
    regexp_extract(pi.p_promo_name, '(\\d+)%', 1)               AS discount_percent,
    pi.total_sales,
    pi.total_profit - pi.total_loss                               AS net_contribution,
    pi.total_returns
FROM promo_items pi
ORDER BY net_contribution DESC
LIMIT 100
