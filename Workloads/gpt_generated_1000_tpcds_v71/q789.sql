WITH joined AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_ext_sales_price AS cs_sales,
        cs.cs_net_profit AS cs_profit,
        cs.cs_quantity AS cs_qty,
        p.p_promo_id,
        p.p_channel_email,
        p.p_channel_tv,
        p.p_discount_active,
        sm.sm_type,
        ws.ws_order_number,
        ws.ws_ext_sales_price AS ws_sales,
        ws.ws_net_profit AS ws_profit,
        ws.ws_quantity AS ws_qty,
        ws.ws_net_paid_inc_ship,
        w.web_state,
        w.web_zip,
        CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END AS promo_active_flag
    FROM catalog_sales cs
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN web_sales ws ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
                     AND ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE p.p_channel_email = 'Y'
      AND p.p_channel_tv = 'Y'
      AND cs.cs_sold_date_sk BETWEEN 2450816 AND 2451175
      AND ws.ws_net_paid_inc_ship > 1000
      AND w.web_zip LIKE '3%'
),
promo_agg AS (
    SELECT
        p_promo_id,
        sm_type,
        SUM(cs_sales) AS total_cs_sales,
        SUM(ws_sales) AS total_ws_sales,
        SUM(cs_profit) AS total_cs_profit,
        SUM(ws_profit) AS total_ws_profit,
        SUM(cs_qty + ws_qty) AS total_qty,
        SUM(promo_active_flag) AS active_promo_count,
        COUNT(*) AS txn_count
    FROM joined
    GROUP BY p_promo_id, sm_type
),
ship_type_summary AS (
    SELECT
        sm_type,
        AVG(total_cs_sales + total_ws_sales) AS avg_sales_per_promo,
        SUM(total_qty) AS sum_qty
    FROM promo_agg
    GROUP BY sm_type
)
SELECT
    pa.p_promo_id,
    pa.sm_type,
    pa.total_cs_sales,
    pa.total_ws_sales,
    (pa.total_cs_sales + pa.total_ws_sales) AS total_sales,
    pa.total_qty,
    CASE WHEN pa.active_promo_count > 0 THEN 'Active' ELSE 'Inactive' END AS promo_status,
    ROW_NUMBER() OVER (PARTITION BY pa.sm_type ORDER BY (pa.total_cs_sales + pa.total_ws_sales) DESC) AS rank_within_ship_type,
    sts.avg_sales_per_promo,
    sts.sum_qty AS ship_type_qty
FROM promo_agg pa
JOIN ship_type_summary sts ON pa.sm_type = sts.sm_type
WHERE (pa.total_cs_sales + pa.total_ws_sales) > 50000
  AND pa.total_qty > 1000
  AND sts.avg_sales_per_promo > 20000
ORDER BY total_sales DESC
LIMIT 100
