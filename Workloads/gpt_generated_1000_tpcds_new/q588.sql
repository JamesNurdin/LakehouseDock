WITH store_agg AS (
    SELECT
        ss_item_sk,
        ss_sold_time_sk,
        ss_promo_sk,
        SUM(ss_net_paid)   AS store_net_paid,
        SUM(ss_net_profit) AS store_net_profit
    FROM store_sales
    WHERE ss_quantity > 1
      AND ss_wholesale_cost > 20
      AND ss_ext_discount_amt < 100
      AND ss_ext_tax BETWEEN 0 AND 50
      AND ss_sold_time_sk IS NOT NULL
      AND ss_promo_sk IS NOT NULL
    GROUP BY ss_item_sk, ss_sold_time_sk, ss_promo_sk
)

SELECT DISTINCT
    i.i_item_id,
    i.i_product_name,
    p.p_promo_name,
    t.t_hour,
    ws.ws_net_paid,
    cs.cs_net_paid,
    sa.store_net_paid,
    CASE
        WHEN (sa.store_net_profit + cs.cs_net_profit + ws.ws_net_profit) > 0 THEN 'POSITIVE'
        ELSE 'NON_POSITIVE'
    END AS total_profit_flag,
    ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY (sa.store_net_paid + cs.cs_net_paid + ws.ws_net_paid) DESC) AS rn,
    w.word AS site_name_word
FROM web_sales ws
RIGHT OUTER JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
LEFT JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN time_dim t
    ON ws.ws_sold_time_sk = t.t_time_sk
LEFT JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN catalog_sales cs
    ON cs.cs_sold_time_sk = t.t_time_sk
   AND cs.cs_item_sk = i.i_item_sk
   AND cs.cs_promo_sk = p.p_promo_sk
LEFT JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN store_agg sa
    ON sa.ss_item_sk = i.i_item_sk
   AND sa.ss_sold_time_sk = t.t_time_sk
   AND sa.ss_promo_sk = p.p_promo_sk
CROSS JOIN UNNEST(split(wsite.web_name, ' ')) AS w(word)
WHERE
    p.p_discount_active = 'Y'
    AND i.i_manufact_id IN (260, 264, 630)
    AND t.t_am_pm = 'PM'
    AND t.t_hour BETWEEN 9 AND 18
    AND cc.cc_state = 'CA'
    AND wsite.web_country = 'United States'
    AND ws.ws_quantity > 0
    AND cs.cs_net_paid > 0
    AND w.word <> ''
ORDER BY total_profit_flag DESC, rn
LIMIT 100
