WITH sampled_cs AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE cs_quantity > 0
)
SELECT
    ws.ws_order_number,
    ws.ws_net_paid,
    ws.ws_sales_price,
    i.i_product_name,
    cc.cc_name AS call_center_name,
    sm.sm_type AS ship_type,
    td.t_hour,
    td.t_am_pm,
    web_site.web_name,
    web_site.web_state,
    promo_agg.promo_cnt,
    wr.wr_return_amt,
    wr.wr_return_quantity,
    ROW_NUMBER() OVER (PARTITION BY web_site.web_name ORDER BY ws.ws_net_paid DESC) AS rn_per_site,
    DENSE_RANK() OVER (ORDER BY ws.ws_net_paid DESC) AS global_rank
FROM sampled_cs cs
JOIN time_dim td
    ON cs.cs_sold_time_sk = td.t_time_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
LEFT JOIN LATERAL (
    SELECT COUNT(*) AS promo_cnt
    FROM promotion p2
    WHERE p2.p_item_sk = i.i_item_sk
) promo_agg ON TRUE
JOIN web_sales ws
    ON i.i_item_sk = ws.ws_item_sk
JOIN time_dim td_ws
    ON ws.ws_sold_time_sk = td_ws.t_time_sk
JOIN web_site
    ON ws.ws_web_site_sk = web_site.web_site_sk
FULL OUTER JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
WHERE
    td.t_hour BETWEEN 8 AND 18
    AND web_site.web_state = 'CA'
    AND web_site.web_mkt_class LIKE '%Broad%'
ORDER BY ws.ws_net_paid DESC
LIMIT 100
