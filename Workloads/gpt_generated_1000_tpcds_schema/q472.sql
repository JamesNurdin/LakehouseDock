WITH warehouse_words AS (
    SELECT w.w_warehouse_sk,
           w.w_city,
           word
    FROM warehouse w
    CROSS JOIN UNNEST(split(w.w_street_name, ' ')) AS t(word)
),
combined AS (
    SELECT d.d_year AS year,
           SUM(ws.ws_net_paid_inc_ship_tax) AS metric_value,
           CASE WHEN p.p_channel_tv = 'Y' THEN 'TV' ELSE 'Other' END AS category
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year,
             CASE WHEN p.p_channel_tv = 'Y' THEN 'TV' ELSE 'Other' END
    UNION ALL
    SELECT d.d_year AS year,
           SUM(cr.cr_return_amount) AS metric_value,
           CASE WHEN cc.cc_state = 'CA' THEN 'CA' ELSE 'Other' END AS category
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse_words ww ON cr.cr_warehouse_sk = ww.w_warehouse_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year,
             CASE WHEN cc.cc_state = 'CA' THEN 'CA' ELSE 'Other' END
)
SELECT combined.year,
       combined.metric_value,
       combined.category,
       ROW_NUMBER() OVER (ORDER BY combined.metric_value DESC) AS rn
FROM combined
ORDER BY combined.metric_value DESC
LIMIT 100
