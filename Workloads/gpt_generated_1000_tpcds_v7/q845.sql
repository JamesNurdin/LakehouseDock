WITH sales_agg AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_warehouse_sq_ft,
        ws.ws_web_site_sk,
        ws.ws_promo_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt,
        AVG(ws.ws_ext_discount_amt) AS avg_discount_amt
    FROM web_sales ws
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name, w.w_warehouse_sq_ft, ws.ws_web_site_sk, ws.ws_promo_sk
),
returns_agg AS (
    SELECT
        cr.cr_warehouse_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS returns_cnt
    FROM catalog_returns cr
    GROUP BY cr.cr_warehouse_sk
),
joined AS (
    SELECT
        sa.w_warehouse_sk,
        sa.w_warehouse_name,
        sa.w_warehouse_sq_ft,
        sa.ws_web_site_sk,
        sa.total_net_profit,
        sa.sales_cnt,
        sa.avg_discount_amt,
        COALESCE(ra.total_return_amount, 0) AS total_return_amount,
        COALESCE(ra.returns_cnt, 0) AS returns_cnt
    FROM sales_agg sa
    LEFT JOIN returns_agg ra
        ON sa.w_warehouse_sk = ra.cr_warehouse_sk
)
SELECT
    j.w_warehouse_name,
    ws.web_name,
    j.total_net_profit,
    j.total_return_amount,
    j.sales_cnt,
    j.returns_cnt,
    j.avg_discount_amt,
    (j.total_net_profit - j.total_return_amount) AS net_profit_after_returns
FROM joined j
JOIN web_site ws
    ON j.ws_web_site_sk = ws.web_site_sk
WHERE
    j.w_warehouse_sq_ft >= 600000
    AND ws.web_manager IS NOT NULL
    AND j.total_net_profit > 20000
ORDER BY
    net_profit_after_returns DESC
LIMIT 100
