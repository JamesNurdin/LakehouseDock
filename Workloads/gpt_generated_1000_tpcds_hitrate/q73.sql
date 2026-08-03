WITH agg_cs AS (
    SELECT
        cs_item_sk,
        cs_order_number,
        cs_promo_sk,
        cs_bill_cdemo_sk,
        SUM(cs_net_paid) AS total_sales
    FROM catalog_sales
    GROUP BY cs_item_sk, cs_order_number, cs_promo_sk, cs_bill_cdemo_sk
)
SELECT
    s1.s_store_id,
    p.p_promo_id,
    cd1.cd_gender AS sales_gender,
    cd2.cd_gender AS bill_gender,
    SUM(agg_cs.total_sales) AS total_sales,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    COUNT(DISTINCT agg_cs.cs_order_number) AS distinct_orders,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales_tickets
FROM promotion p
LEFT JOIN agg_cs
    ON agg_cs.cs_promo_sk = p.p_promo_sk
LEFT JOIN catalog_returns cr
    ON agg_cs.cs_item_sk = cr.cr_item_sk
   AND agg_cs.cs_order_number = cr.cr_order_number
LEFT JOIN customer_demographics cd2
    ON agg_cs.cs_bill_cdemo_sk = cd2.cd_demo_sk
FULL OUTER JOIN store_sales ss
    ON ss.ss_promo_sk = p.p_promo_sk
FULL OUTER JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
JOIN store s1 TABLESAMPLE BERNOULLI (5)
    ON ss.ss_store_sk = s1.s_store_sk
JOIN store s2
    ON sr.sr_store_sk = s2.s_store_sk
JOIN customer_demographics cd1
    ON ss.ss_cdemo_sk = cd1.cd_demo_sk
JOIN customer_demographics cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_demographics cd_ret
    ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
GROUP BY CUBE (s1.s_store_id, p.p_promo_id, cd1.cd_gender, cd2.cd_gender)
ORDER BY total_sales DESC
LIMIT 100
