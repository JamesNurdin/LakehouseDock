/* Goal: Analyze combined returns and sales performance by year, warehouse, and return reason, including promotion activity and catalog return metrics, filtering for 2002, California warehouses, and specific return reasons. */
WITH store_agg AS (
    SELECT
        sr.sr_reason_sk,
        sr.sr_returned_date_sk,
        SUM(sr.sr_net_loss) AS store_net_loss,
        COUNT(*) AS store_return_cnt
    FROM store_returns sr
    WHERE sr.sr_return_tax > 5.00
    GROUP BY sr.sr_reason_sk, sr.sr_returned_date_sk
),
web_agg AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_profit) AS web_net_profit,
        COUNT(*) AS web_sales_cnt
    FROM web_sales ws
    TABLESAMPLE BERNOULLI (10)
    WHERE ws.ws_quantity > 1
    GROUP BY ws.ws_web_site_sk, ws.ws_sold_date_sk
)
SELECT
    d.d_year,
    w.w_warehouse_name,
    r.r_reason_desc,
    sa.store_net_loss,
    wa.web_net_profit,
    cr_cnt.catalog_return_cnt,
    (
        SELECT SUM(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_warehouse_sk = w.w_warehouse_sk
          AND cr2.cr_returned_date_sk = d.d_date_sk
    ) AS total_return_amount,
    CASE WHEN EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = wp.ws_promo_sk
          AND p2.p_discount_active = 'Y'
    ) THEN 1 ELSE 0 END AS promo_active_flag
FROM date_dim d
FULL OUTER JOIN (
    SELECT ws.*, p.p_promo_name
    FROM web_sales ws
    FULL OUTER JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
) wp
    ON wp.ws_sold_date_sk = d.d_date_sk
LEFT JOIN store_agg sa
    ON sa.sr_returned_date_sk = d.d_date_sk
LEFT JOIN reason r
    ON r.r_reason_sk = sa.sr_reason_sk
LEFT JOIN warehouse w
    ON w.w_warehouse_sk = wp.ws_warehouse_sk
LEFT JOIN (
    SELECT
        cr.cr_warehouse_sk,
        cr.cr_returned_date_sk,
        COUNT(*) AS catalog_return_cnt
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 100.00
    GROUP BY cr.cr_warehouse_sk, cr.cr_returned_date_sk
) cr_cnt
    ON cr_cnt.cr_warehouse_sk = w.w_warehouse_sk
   AND cr_cnt.cr_returned_date_sk = d.d_date_sk
LEFT JOIN web_agg wa
    ON wa.ws_sold_date_sk = d.d_date_sk
   AND wa.ws_web_site_sk = wp.ws_web_site_sk
LEFT JOIN web_site wsit
    ON wsit.web_site_sk = wp.ws_web_site_sk
   AND wsit.web_open_date_sk = d.d_date_sk
WHERE w.w_state = 'CA'
  AND r.r_reason_desc LIKE '%size%'
  AND d.d_year = 2002
ORDER BY d.d_year DESC, w.w_warehouse_name
OFFSET 0
LIMIT 100
