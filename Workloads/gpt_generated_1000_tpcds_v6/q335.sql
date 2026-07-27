WITH base AS (
    SELECT
        s.s_store_name,
        i.i_category,
        i.i_product_name,
        i.i_item_sk,
        ws.ws_ext_sales_price,
        ws.ws_net_paid_inc_tax,
        ws.ws_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        p.p_discount_active
    FROM store s
    JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd_bill ON sr.sr_hdemo_sk = hd_bill.hd_demo_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    WHERE s.s_state = 'CA'
      AND i.i_current_price BETWEEN 10 AND 100
      AND ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
) 
SELECT
    base.s_store_name,
    base.i_category,
    SUM(base.ws_ext_sales_price) AS total_sales,
    SUM(base.sr_return_amt) AS total_return_amount,
    SUM(base.sr_net_loss) AS total_net_loss,
    AVG(base.ws_quantity) AS avg_quantity,
    COALESCE(base.p_discount_active, 'N') AS promo_active_flag,
    (
        SELECT COUNT(*)
        FROM promotion p2
        WHERE p2.p_discount_active = 'Y'
          AND p2.p_item_sk = base.i_item_sk
    ) AS active_promo_count
FROM base
GROUP BY
    base.s_store_name,
    base.i_category,
    base.p_discount_active,
    base.i_item_sk
HAVING
    SUM(base.ws_ext_sales_price) > 1000
    AND SUM(base.sr_net_loss) > 0
    AND COUNT(*) >= 5
ORDER BY total_sales DESC
LIMIT 100
