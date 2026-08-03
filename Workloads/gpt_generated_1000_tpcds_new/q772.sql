WITH
    cs_sampled AS (
        SELECT *
        FROM catalog_sales
        TABLESAMPLE BERNOULLI (10)
    ),
    intersect_orders AS (
        SELECT cs.cs_order_number
        FROM cs_sampled cs
        INTERSECT
        SELECT cr.cr_order_number
        FROM catalog_returns cr
    ),
    except_orders AS (
        SELECT cs.cs_order_number
        FROM cs_sampled cs
        EXCEPT
        SELECT cr.cr_order_number
        FROM catalog_returns cr
    )
SELECT
    cs.cs_order_number,
    d.d_year,
    s.s_store_name,
    w.w_warehouse_name,
    w.w_state,
    p.p_promo_name,
    p.p_discount_active,
    cc.cc_name,
    cp.cp_catalog_page_number,
    cd.cd_gender,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ca.ca_city,
    cs.cs_net_paid,
    cs.cs_net_profit,
    cr.cr_return_amount,
    wr.wr_return_amt,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY cs.cs_net_paid DESC) AS store_sales_rank,
    (SELECT COUNT(*) FROM intersect_orders) AS intersect_order_cnt,
    (SELECT COUNT(*) FROM except_orders) AS except_order_cnt
FROM cs_sampled cs
JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
FULL OUTER JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
FULL OUTER JOIN store_sales ss
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_returned_date_sk = d.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
LEFT JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE d.d_year = 2001
  AND p.p_discount_active = 'Y'
  AND w.w_state = 'CA'
ORDER BY store_sales_rank
LIMIT 100
