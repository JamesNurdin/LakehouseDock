WITH agg_sales AS (
    SELECT
        ss_customer_sk,
        ss_store_sk,
        ss_promo_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(*) AS txn_count,
        AVG(ss_net_profit) AS avg_profit,
        MIN(ss_sold_date_sk) AS first_sale_date_sk,
        MAX(ss_sold_date_sk) AS last_sale_date_sk
    FROM store_sales
    WHERE ss_quantity > 1
      AND ss_sales_price > 20
      AND ss_ext_discount_amt < 5
      AND ss_coupon_amt = 0
      AND ss_sold_date_sk BETWEEN 2450000 AND 2450200
      AND ss_net_paid > 0
    GROUP BY ss_customer_sk, ss_store_sk, ss_promo_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    cd.cd_gender,
    s.s_store_name,
    p.p_promo_name,
    agg.total_sales,
    agg.txn_count,
    agg.avg_profit,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY agg.total_sales DESC) AS store_sales_rank,
    lc.customer_count
FROM agg_sales AS agg
JOIN customer c
    ON agg.ss_customer_sk = c.c_customer_sk
JOIN store s
    ON agg.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON agg.ss_promo_sk = p.p_promo_sk
JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN LATERAL (
    SELECT COUNT(DISTINCT ss2.ss_customer_sk) AS customer_count
    FROM store_sales ss2
    WHERE ss2.ss_store_sk = s.s_store_sk
      AND ss2.ss_sold_date_sk BETWEEN 2450000 AND 2450200
) AS lc ON TRUE
WHERE c.c_birth_country IN ('GAMBIA', 'TOGO', 'SWITZERLAND')
  AND ca.ca_gmt_offset = -5.00
  AND ca.ca_location_type = 'apartment'
  AND cd.cd_dep_college_count >= 2
  AND p.p_channel_email = 'Y'
  AND s.s_state = 'CA'
ORDER BY agg.total_sales DESC
