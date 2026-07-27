WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_order_number,
        cs.cs_ext_tax,
        cs.cs_net_paid,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_net_profit
    FROM catalog_sales cs
    WHERE cs.cs_ext_tax > 10
)
SELECT
    i.i_category,
    i.i_brand,
    p.p_promo_name,
    CASE WHEN cr.cr_net_loss > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cs.cs_net_paid) AS avg_net_paid,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    MIN(cr.cr_return_amount) AS min_return_amount,
    MAX(cr.cr_return_amount) AS max_return_amount
FROM filtered_sales cs
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN catalog_returns cr
    ON cr.cr_item_sk = cs.cs_item_sk
    AND cr.cr_order_number = cs.cs_order_number
WHERE
    i.i_class IN ('costume', 'toddlers')
    AND i.i_current_price > 20
    AND p.p_discount_active = 'Y'
    AND cr.cr_return_quantity > 0
    AND EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_item_sk = i.i_item_sk
          AND wr.wr_reversed_charge > 100
    )
GROUP BY
    i.i_category,
    i.i_brand,
    p.p_promo_name,
    CASE WHEN cr.cr_net_loss > 1000 THEN 'High' ELSE 'Low' END
HAVING
    SUM(cr.cr_net_loss) > 5000
    AND COUNT(DISTINCT cs.cs_order_number) > 10
ORDER BY total_net_loss DESC
LIMIT 100
