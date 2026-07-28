WITH agg AS (
    SELECT
        d.d_year,
        s.s_state,
        i.i_category,
        SUM(ss.ss_net_paid_inc_tax) AS total_store_sales,
        SUM(cs.cs_net_paid_inc_tax) AS total_catalog_sales,
        SUM(cr.cr_return_amount) AS total_returns,
        COUNT(DISTINCT i.i_item_sk) AS distinct_items,
        SUM(p.p_cost) AS total_promo_cost
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'TX'
      AND p.p_cost > 500
      AND ss.ss_net_paid_inc_tax > 100
      AND r.r_reason_desc LIKE '%damage%'
    GROUP BY GROUPING SETS (
        (d.d_year, s.s_state, i.i_category),
        (d.d_year, s.s_state),
        (d.d_year, i.i_category),
        (d.d_year)
    )
)
SELECT
    d_year,
    s_state,
    i_category,
    total_store_sales,
    total_catalog_sales,
    total_returns,
    distinct_items,
    total_promo_cost,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_store_sales DESC) AS rank_by_sales
FROM agg
WHERE total_store_sales > 10000
ORDER BY total_store_sales DESC
LIMIT 100
