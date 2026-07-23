SELECT
    cs.cs_order_number,
    cc.cc_call_center_id,
    cp.cp_catalog_page_id,
    p.p_promo_id,
    ca.ca_state,
    t.t_hour,
    cd.cd_gender,
    hd.hd_income_band_sk,
    wsit.web_name,
    cs.cs_ext_sales_price,
    COALESCE(sr.sr_return_amt, 0) AS store_return_amount,
    COALESCE(wr.wr_return_amt, 0) AS web_return_amount,
    cs.cs_ext_sales_price - COALESCE(sr.sr_return_amt, 0) - COALESCE(wr.wr_return_amt, 0) AS net_sales_adj,
    RANK() OVER (PARTITION BY ca.ca_state ORDER BY cs.cs_ext_sales_price DESC) AS sales_rank_state,
    DENSE_RANK() OVER (ORDER BY (cs.cs_ext_sales_price - COALESCE(sr.sr_return_amt, 0) - COALESCE(wr.wr_return_amt, 0)) DESC) AS overall_net_sales_dense_rank,
    (
        SELECT AVG(cs2.cs_ext_sales_price)
        FROM catalog_sales cs2
        WHERE cs2.cs_call_center_sk = cs.cs_call_center_sk
    ) AS avg_sales_by_call_center
FROM catalog_sales cs
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN store_returns sr
    ON sr.sr_return_time_sk = t.t_time_sk
LEFT JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_sales ws
    ON ws.ws_sold_time_sk = t.t_time_sk
JOIN web_site wsit
    ON ws.ws_web_site_sk = wsit.web_site_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_time_sk = t.t_time_sk
   AND wr.wr_item_sk = ws.ws_item_sk
   AND wr.wr_order_number = ws.ws_order_number
WHERE
    cc.cc_state = 'CA'
    AND p.p_discount_active = 'Y'
    AND t.t_hour BETWEEN 9 AND 17
    AND cs.cs_ext_sales_price > 1000
    AND cd.cd_purchase_estimate >= 5000
ORDER BY net_sales_adj DESC
LIMIT 100
