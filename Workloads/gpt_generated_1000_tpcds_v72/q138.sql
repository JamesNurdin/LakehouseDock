WITH ss_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_customer_sk,
        ss.ss_promo_sk,
        SUM(ss.ss_net_paid)               AS store_net_paid,
        SUM(ss.ss_ext_discount_amt)       AS store_ext_discount,
        COUNT(*)                          AS sales_cnt
    FROM store_sales ss
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk, ss.ss_customer_sk, ss.ss_promo_sk
)
SELECT
    s.s_store_name,
    d_sales.d_year,
    d_sales.d_month_seq,
    SUM(ss_agg.store_net_paid)                                            AS total_net_paid,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN ss_agg.store_ext_discount ELSE 0 END) AS total_active_promo_discount,
    COUNT(DISTINCT c.c_customer_id)                                         AS unique_customers,
    SUM(cs.cs_net_paid)                                                     AS catalog_total_net_paid,
    SUM(inv.inv_quantity_on_hand)                                           AS total_inventory_on_hand,
    SUM(wr.wr_net_loss)                                                     AS total_return_loss
FROM ss_agg
JOIN store s
    ON ss_agg.ss_store_sk = s.s_store_sk
JOIN date_dim d_sales
    ON ss_agg.ss_sold_date_sk = d_sales.d_date_sk
JOIN customer c
    ON ss_agg.ss_customer_sk = c.c_customer_sk
JOIN promotion p
    ON ss_agg.ss_promo_sk = p.p_promo_sk
JOIN catalog_sales cs
    ON cs.cs_bill_customer_sk = c.c_customer_sk
   AND cs.cs_sold_date_sk = d_sales.d_date_sk
JOIN call_center cc_closed
    ON cs.cs_call_center_sk = cc_closed.cc_call_center_sk
JOIN date_dim d_cc_closed
    ON cc_closed.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN call_center cc_open
    ON cs.cs_call_center_sk = cc_open.cc_call_center_sk
JOIN date_dim d_cc_open
    ON cc_open.cc_open_date_sk = d_cc_open.d_date_sk
JOIN inventory inv
    ON inv.inv_date_sk = d_sales.d_date_sk
JOIN web_returns wr
    ON wr.wr_refunded_customer_sk = c.c_customer_sk
   AND wr.wr_returned_date_sk = d_sales.d_date_sk
WHERE EXISTS (
    SELECT 1
    FROM web_page wp
    WHERE wp.wp_customer_sk = c.c_customer_sk
      AND wp.wp_autogen_flag = 'Y'
)
GROUP BY s.s_store_name, d_sales.d_year, d_sales.d_month_seq
ORDER BY total_net_paid DESC
LIMIT 100
