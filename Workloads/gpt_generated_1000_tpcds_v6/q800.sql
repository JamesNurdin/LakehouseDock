WITH raw_data AS (
    SELECT
        s.s_state,
        s.s_store_id,
        p.p_promo_id,
        p.p_discount_active,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        cd.cd_dep_employed_count,
        r.r_reason_id,
        r.r_reason_desc,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        sr.sr_return_amt,
        wr.wr_return_amt,
        wp.wp_type
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returning_customer_sk = c.c_customer_sk
        AND wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE cd.cd_purchase_estimate > 1000
      AND cd.cd_dep_employed_count >= 1
      AND p.p_discount_active = 'Y'
      AND s.s_state IN ('CA', 'TX', 'NY')
      AND wp.wp_type = 'product'
      AND cd.cd_gender = 'M'
      AND r.r_reason_id = 'AAAAAAAALAAAAAAA'
      AND EXISTS (
          SELECT 1 FROM (
              SELECT DISTINCT s_store_id FROM store WHERE s_state = s.s_state
          ) ds
          WHERE ds.s_store_id = s.s_store_id
      )
),
agg_data AS (
    SELECT
        s_state,
        p_promo_id,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        SUM(COALESCE(sr_return_amt, 0)) AS total_store_return,
        SUM(COALESCE(wr_return_amt, 0)) AS total_web_return,
        COUNT(DISTINCT c_customer_id) AS distinct_customers
    FROM raw_data
    GROUP BY GROUPING SETS (
        (s_state, p_promo_id),
        (s_state),
        (p_promo_id),
        ()
    )
)
SELECT
    s_state,
    p_promo_id,
    total_sales,
    total_profit,
    total_store_return,
    total_web_return,
    distinct_customers,
    total_sales - (total_store_return + total_web_return) AS net_sales_after_returns,
    (SELECT AVG(cd5.cd_purchase_estimate)
       FROM customer_demographics cd5
       WHERE cd5.cd_gender = 'M') AS avg_male_purchase_estimate
FROM agg_data
WHERE (total_sales > 10000 OR total_profit > 5000)
  AND distinct_customers >= 10
  AND s_state IS NOT NULL
  AND p_promo_id IS NOT NULL
  AND (total_store_return + total_web_return) < total_sales
ORDER BY net_sales_after_returns DESC
LIMIT 100
