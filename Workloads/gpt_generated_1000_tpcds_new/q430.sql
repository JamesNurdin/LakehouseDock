WITH agg_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        SUM(ss.ss_net_paid)   AS total_net_paid,
        COUNT(*)               AS cnt_sales
    FROM store_sales ss
    GROUP BY ss.ss_store_sk, ss.ss_item_sk, ss.ss_hdemo_sk, ss.ss_addr_sk
)
SELECT
    s.s_store_name,
    i.i_item_desc,
    p.p_promo_name,
    d_store_closed.d_year                AS store_closed_year,
    hd.hd_buy_potential,
    ca.ca_state,
    agg.total_net_paid,
    agg.cnt_sales,
    LAG(agg.total_net_paid) OVER (PARTITION BY s.s_store_sk ORDER BY agg.total_net_paid DESC) AS prev_store_sales,
    (SELECT MAX(i2.i_current_price) FROM item i2)                                            AS max_item_price,
    r.r_reason_desc,
    cr.cr_return_amount,
    wr.wr_return_amt,
    inv.inv_quantity_on_hand
FROM agg_sales agg
JOIN store s
    ON agg.ss_store_sk = s.s_store_sk
JOIN item i
    ON agg.ss_item_sk = i.i_item_sk
JOIN promotion p
    ON p.p_item_sk = i.i_item_sk
JOIN household_demographics hd
    ON agg.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
    ON agg.ss_addr_sk = ca.ca_address_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
/* catalog side */
JOIN catalog_sales cs
    ON cs.cs_item_sk = i.i_item_sk
JOIN date_dim d_cat
    ON cs.cs_sold_date_sk = d_cat.d_date_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
/* catalog returns */
JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
   AND cr.cr_order_number = cs.cs_order_number
JOIN date_dim d_cr
    ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
/* store returns */
JOIN store_returns sr
    ON sr.sr_store_sk = s.s_store_sk
   AND sr.sr_item_sk = i.i_item_sk
JOIN reason r_sr
    ON sr.sr_reason_sk = r_sr.r_reason_sk
/* web returns */
JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
/* inventory sampled */
JOIN (
    SELECT * FROM inventory TABLESAMPLE BERNOULLI (10)
) inv
    ON inv.inv_item_sk = i.i_item_sk
JOIN date_dim d_inv
    ON inv.inv_date_sk = d_inv.d_date_sk
WHERE
    /* selective predicates */
    d_store_closed.d_year = 2001
    AND i.i_brand = 'Brand#12'
    AND hd.hd_buy_potential = '1001-5000'
    AND ca.ca_state = 'TX'
    AND p.p_discount_active = 'Y'
    /* anti‑semi join */
    AND agg.ss_item_sk NOT IN (SELECT cr2.cr_item_sk FROM catalog_returns cr2)
LIMIT 100
