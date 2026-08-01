WITH
    -- Base sales data with required filters
    sales_base AS (
        SELECT
            cs.cs_order_number,
            cs.cs_sold_date_sk,
            cs.cs_ship_date_sk,
            cs.cs_call_center_sk,
            cs.cs_promo_sk,
            cs.cs_net_paid,
            cs.cs_net_profit,
            d.d_year,
            cc.cc_call_center_id,
            p.p_promo_id,
            sm.sm_type,
            w.w_warehouse_id
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        WHERE d.d_year = 2001
          AND sm.sm_type = 'AIR'
          AND p.p_discount_active = 'Y'
          AND cc.cc_state = 'CA'
    ),
    -- Base returns data with matching filters
    returns_base AS (
        SELECT
            cr.cr_order_number,
            cr.cr_return_amount,
            cc.cc_call_center_id
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        WHERE d.d_year = 2001
          AND cr.cr_return_amount > 0
    ),
    -- Union of call‑center ids appearing in sales or returns (set operation)
    union_sales_returns AS (
        SELECT cc_call_center_id FROM sales_base
        UNION ALL
        SELECT cc_call_center_id FROM returns_base
    ),
    -- Intersection of call‑center ids that appear in both sales and returns (INTERSECT)
    intersect_cc AS (
        SELECT cc_call_center_id FROM sales_base
        INTERSECT
        SELECT cc_call_center_id FROM returns_base
    ),
    -- Aggregated metrics per call center, promotion and year
    final_agg AS (
        SELECT
            sb.cc_call_center_id,
            p.p_promo_id,
            sb.d_year,
            SUM(sb.cs_net_paid)               AS total_paid,
            SUM(sb.cs_net_profit)             AS total_profit,
            COUNT(*)                          AS sales_cnt,
            COALESCE(SUM(rb.cr_return_amount), 0) AS total_return_amount
        FROM sales_base sb
        LEFT JOIN returns_base rb ON sb.cs_order_number = rb.cr_order_number
        JOIN promotion p ON sb.cs_promo_sk = p.p_promo_sk
        WHERE NOT EXISTS (
            SELECT 1 FROM catalog_returns cr2
            WHERE cr2.cr_order_number = sb.cs_order_number
              AND cr2.cr_return_amount > 500
        )
          AND sb.cc_call_center_id IN (SELECT cc_call_center_id FROM intersect_cc)
        GROUP BY sb.cc_call_center_id, p.p_promo_id, sb.d_year
        HAVING SUM(sb.cs_net_paid) > 10000
    )
SELECT
    f.cc_call_center_id,
    f.p_promo_id,
    f.d_year,
    f.total_paid,
    f.total_profit,
    f.sales_cnt,
    f.total_return_amount,
    RANK() OVER (PARTITION BY f.d_year ORDER BY f.total_profit DESC) AS profit_rank,
    f.total_paid / (SELECT AVG(total_paid) FROM final_agg) AS paid_vs_average
FROM final_agg f
-- Join to a single representative closed‑date for the store (anti‑join already applied above)
JOIN store st ON st.s_closed_date_sk = (
    SELECT MIN(d2.d_date_sk) FROM date_dim d2 WHERE d2.d_year = f.d_year
)
-- Join to a single representative open‑date for the web site
JOIN web_site ws ON ws.web_open_date_sk = (
    SELECT MIN(d3.d_date_sk) FROM date_dim d3 WHERE d3.d_year = f.d_year
)
WHERE st.s_market_desc LIKE '%Financial%'
  AND ws.web_name = 'Online Store'
ORDER BY f.total_profit DESC
LIMIT 100
