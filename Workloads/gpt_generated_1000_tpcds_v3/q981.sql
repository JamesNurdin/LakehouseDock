WITH store_sales_agg AS (
    SELECT
        ss_customer_sk,
        ss_hdemo_sk,
        ss_promo_sk,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(ss_ext_sales_price) AS total_ext_sales_price,
        COUNT(*) AS sales_transactions
    FROM store_sales
    WHERE ss_wholesale_cost > 60.00
      AND ss_ticket_number > 5
    GROUP BY ss_customer_sk, ss_hdemo_sk, ss_promo_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    hd.hd_buy_potential,
    p.p_channel_dmail,
    cp.cp_department,
    SUM(cs.cs_net_paid) AS catalog_total_net_paid,
    SUM(cs.cs_ext_sales_price) AS catalog_total_ext_sales_price,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
    sa.total_net_paid,
    sa.total_ext_sales_price,
    sa.sales_transactions
FROM store_sales_agg sa
JOIN customer c
    ON sa.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON sa.ss_hdemo_sk = hd.hd_demo_sk
   AND c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN promotion p
    ON sa.ss_promo_sk = p.p_promo_sk
JOIN catalog_sales cs
    ON cs.cs_bill_customer_sk = c.c_customer_sk
   AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   AND cs.cs_promo_sk = p.p_promo_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE p.p_channel_dmail = 'Y'
  AND hd.hd_buy_potential = '>10000'
  AND cp.cp_type = 'S'
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    hd.hd_buy_potential,
    p.p_channel_dmail,
    cp.cp_department,
    sa.total_net_paid,
    sa.total_ext_sales_price,
    sa.sales_transactions
ORDER BY catalog_total_net_paid DESC
LIMIT 100
