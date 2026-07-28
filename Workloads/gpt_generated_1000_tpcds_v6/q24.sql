WITH sales_agg AS (
    SELECT
        cc.cc_call_center_id,
        s.s_store_id,
        p.p_promo_id,
        t.t_hour,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(sr.sr_return_amt) AS total_store_returns
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN web_sales ws ON ws.ws_sold_time_sk = t.t_time_sk
                     AND ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr ON sr.sr_return_time_sk = t.t_time_sk
    LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE p.p_discount_active = 'N'
      AND t.t_hour BETWEEN 9 AND 17
      AND cc.cc_name LIKE '%Center%'
    GROUP BY cc.cc_call_center_id, s.s_store_id, p.p_promo_id, t.t_hour
)
SELECT
    sa.cc_call_center_id,
    sa.s_store_id,
    sa.p_promo_id,
    sa.t_hour,
    sa.total_catalog_sales,
    sa.total_web_sales,
    sa.total_store_returns,
    (sa.total_catalog_sales + sa.total_web_sales) - COALESCE(sa.total_store_returns, 0) AS net_sales,
    (SELECT AVG(total_catalog_sales) FROM sales_agg) AS avg_catalog_sales_all
FROM sales_agg sa
WHERE (sa.total_catalog_sales + sa.total_web_sales) > (
        SELECT AVG(total_web_sales) FROM sales_agg
      )
ORDER BY net_sales DESC
LIMIT 100
