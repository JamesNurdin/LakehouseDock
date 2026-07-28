WITH ss_agg AS (
    SELECT
        ss_store_sk,
        ss_sold_date_sk,
        SUM(ss_net_paid) AS total_net_paid
    FROM store_sales
    GROUP BY ss_store_sk, ss_sold_date_sk
)

SELECT
    d.d_year,
    s.s_store_name,
    i.i_brand,
    p.p_promo_name,
    SUM(ss_agg.total_net_paid) AS store_sales_total,
    SUM(ws.ws_net_paid) AS web_sales_total,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    CASE
        WHEN SUM(ss_agg.total_net_paid) > 1000000 THEN 'HIGH'
        ELSE 'LOW'
    END AS sales_category
FROM ss_agg
JOIN store s
    ON ss_agg.ss_store_sk = s.s_store_sk
JOIN date_dim d
    ON ss_agg.ss_sold_date_sk = d.d_date_sk
JOIN store_returns sr
    ON sr.sr_store_sk = s.s_store_sk
    AND sr.sr_returned_date_sk = d.d_date_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_date_sk = d.d_date_sk
WHERE
    d.d_year = 2001
    AND i.i_brand = 'Brand#23'
    AND c.c_birth_year BETWEEN 1965 AND 1975
    AND p.p_discount_active = 'Y'
    AND cc.cc_state = 'CA'
GROUP BY
    d.d_year,
    s.s_store_name,
    i.i_brand,
    p.p_promo_name
LIMIT 100
