/*
Goal: Compute per‑call‑center and per‑promotion sales performance by combining catalog and web sales, then derive overall metrics such as average total sales and total profit, filtering to only high‑profit groups. The query demonstrates multi‑table joins, a CTE with aggregation, a scalar subquery, HAVING, and ordering.
*/
WITH sales_agg AS (
    SELECT
        cc.cc_call_center_id,
        p.p_promo_id,
        sm.sm_type,
        td.t_hour,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
        SUM(cs.cs_net_profit)       AS catalog_profit,
        SUM(ws.ws_ext_sales_price) AS web_sales_amount,
        SUM(ws.ws_net_profit)       AS web_profit
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = td.t_time_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        AND ws.ws_promo_sk = p.p_promo_sk
    WHERE cc.cc_zip IN ('33951', '41933')
      AND cc.cc_sq_ft > 0
      AND td.t_second IN (5, 13)
      AND p.p_response_target = 1
      AND sm.sm_type = 'AIR'
    GROUP BY
        cc.cc_call_center_id,
        p.p_promo_id,
        sm.sm_type,
        td.t_hour
)
SELECT
    sa.cc_call_center_id,
    sa.p_promo_id,
    AVG(sa.catalog_sales_amount + sa.web_sales_amount) AS avg_total_sales,
    SUM(sa.catalog_profit + sa.web_profit)               AS total_profit,
    (
        SELECT SUM(cs_ext_sales_price)
        FROM catalog_sales
    )                                                    AS overall_catalog_sales
FROM sales_agg sa
GROUP BY
    sa.cc_call_center_id,
    sa.p_promo_id
HAVING SUM(sa.catalog_profit + sa.web_profit) > 10000
ORDER BY total_profit DESC
LIMIT 100
