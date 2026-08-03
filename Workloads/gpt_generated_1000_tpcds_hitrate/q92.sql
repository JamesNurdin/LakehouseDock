WITH ss_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        SUM(ss.ss_quantity)           AS total_quantity,
        SUM(ss.ss_net_paid)           AS total_net_paid
    FROM store_sales ss
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk, ss.ss_item_sk
)
,
cr_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        COUNT(*) AS return_count
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    GROUP BY cs.cs_item_sk, cs.cs_sold_date_sk
)
,
wr_agg AS (
    SELECT
        wr.wr_item_sk,
        wr.wr_returned_date_sk,
        COUNT(*) AS web_return_count
    FROM web_returns wr
    GROUP BY wr.wr_item_sk, wr.wr_returned_date_sk
)
SELECT
    s.s_store_name,
    d_sales.d_year,
    i.i_category,
    p.p_promo_name,
    cc.cc_name,
    w.w_warehouse_name,
    ca.ca_state               AS customer_state,
    total_net_paid,
    total_quantity,
    COALESCE(cr.return_count, 0)   AS catalog_return_cnt,
    COALESCE(wr.web_return_count, 0) AS web_return_cnt,
    RANK() OVER (PARTITION BY d_sales.d_year ORDER BY total_net_paid DESC) AS sales_rank,
    (SELECT AVG(total_net_paid) FROM ss_agg) AS avg_net_paid_all_stores
FROM ss_agg
JOIN store s
    ON ss_agg.ss_store_sk = s.s_store_sk
JOIN date_dim d_sales
    ON ss_agg.ss_sold_date_sk = d_sales.d_date_sk
JOIN item i
    ON ss_agg.ss_item_sk = i.i_item_sk
JOIN catalog_sales cs
    ON cs.cs_item_sk = i.i_item_sk
   AND cs.cs_sold_date_sk = d_sales.d_date_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN cr_agg cr
    ON cr.cs_item_sk = ss_agg.ss_item_sk
   AND cr.cs_sold_date_sk = ss_agg.ss_sold_date_sk
LEFT JOIN wr_agg wr
    ON wr.wr_item_sk = ss_agg.ss_item_sk
   AND wr.wr_returned_date_sk = d_sales.d_date_sk
JOIN store_returns sr
    ON sr.sr_store_sk = s.s_store_sk
   AND sr.sr_item_sk = i.i_item_sk
WHERE
    d_sales.d_year = 2001
    AND i.i_category = 'Sports'
    AND s.s_state = 'CA'
    AND ib.ib_lower_bound >= 50000
    AND p.p_discount_active = 'Y'
    AND cc.cc_country = 'United States'
    AND ca.ca_country = 'United States'
ORDER BY sales_rank, total_net_paid DESC
LIMIT 100
