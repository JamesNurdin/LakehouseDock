WITH cr_agg AS (
    SELECT
        cr_call_center_sk,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_return_quantity) AS total_return_qty
    FROM catalog_returns
    WHERE cr_return_amount > 0
    GROUP BY cr_call_center_sk
)
SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_state,
    cr_agg.total_return_amount,
    cr_agg.total_return_qty,
    p.p_promo_name,
    ws.ws_sold_date_sk,
    ws.ws_ext_sales_price,
    RANK() OVER (PARTITION BY cc.cc_call_center_id ORDER BY cr_agg.total_return_amount DESC) AS return_rank,
    CASE
        WHEN ws.ws_ext_sales_price > 10000 THEN 'HIGH'
        ELSE 'NORMAL'
    END AS sales_category
FROM cr_agg
JOIN call_center cc
    ON cr_agg.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_returns cr
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN customer_demographics cd
    ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN web_sales ws
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
WHERE
    cc.cc_state = 'CA'
    AND cd.cd_marital_status = 'M'
    AND p.p_channel_dmail = 'Y'
    AND ws.ws_wholesale_cost > 30
    AND EXISTS (
        SELECT 1 FROM promotion p2
        WHERE p2.p_promo_sk = ws.ws_promo_sk
          AND p2.p_discount_active = 'Y'
    )
ORDER BY cr_agg.total_return_amount DESC
LIMIT 100
