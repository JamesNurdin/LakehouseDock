WITH catalog_agg AS (
    SELECT
        td.t_sub_shift AS sub_shift,
        p.p_promo_name AS promo_name,
        SUM(cs.cs_net_paid) AS net_paid,
        'catalog' AS channel
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE td.t_sub_shift = 'morning'
      AND cs.cs_ext_discount_amt > 1000
    GROUP BY td.t_sub_shift, p.p_promo_name
),
web_agg AS (
    SELECT
        td.t_sub_shift AS sub_shift,
        p.p_promo_name AS promo_name,
        SUM(ws.ws_net_paid) AS net_paid,
        'web' AS channel
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE td.t_sub_shift = 'afternoon'
      AND ws.ws_ext_discount_amt > 1000
    GROUP BY td.t_sub_shift, p.p_promo_name
)
SELECT *
FROM catalog_agg
UNION ALL
SELECT *
FROM web_agg
ORDER BY net_paid DESC, sub_shift
LIMIT 100
