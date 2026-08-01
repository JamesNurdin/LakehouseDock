WITH
    sampled_catalog_sales AS (
        SELECT *
        FROM catalog_sales TABLESAMPLE BERNOULLI (10)
    ),
    agg_store_sales AS (
        SELECT
            ss_store_sk,
            ss_customer_sk,
            ss_hdemo_sk,
            ss_sold_time_sk,
            ss_sold_date_sk,
            ss_promo_sk,
            SUM(ss_net_paid)          AS total_net_paid,
            SUM(ss_quantity)          AS total_quantity,
            COUNT(*)                  AS sales_transactions
        FROM store_sales
        GROUP BY ss_store_sk, ss_customer_sk, ss_hdemo_sk, ss_sold_time_sk, ss_sold_date_sk, ss_promo_sk
    ),
    agg_store_returns AS (
        SELECT
            sr_store_sk,
            SUM(sr_net_loss) AS total_net_loss,
            COUNT(*)         AS return_transactions
        FROM store_returns
        GROUP BY sr_store_sk
    ),
    intersected_stores AS (
        SELECT s_store_sk
        FROM (
            SELECT DISTINCT s_store_sk FROM store WHERE s_state = 'CA'
        )
        INTERSECT
        SELECT DISTINCT ss_store_sk FROM store_sales WHERE ss_quantity > 5
    ),
    excepted_customers AS (
        SELECT cs_bill_customer_sk
        FROM (
            SELECT DISTINCT cs_bill_customer_sk FROM sampled_catalog_sales WHERE cs_ext_sales_price > 1000
        )
        EXCEPT
        SELECT DISTINCT c_customer_sk FROM customer WHERE c_preferred_cust_flag = 'Y'
    )
SELECT
    s.s_state,
    p.p_promo_id,
    t.t_hour,
    COUNT(DISTINCT c.c_customer_sk)                                         AS distinct_customers,
    SUM(agg.total_net_paid)                                                 AS sum_net_paid,
    AVG(agg.total_quantity)                                                AS avg_quantity,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN agg.total_net_paid * 0.9 ELSE agg.total_net_paid END) AS adjusted_net_paid,
    SUM(ret.total_net_loss)                                                AS sum_return_loss,
    (SELECT SUM(total_net_loss) FROM agg_store_returns)                  AS overall_return_loss,
    (SELECT COUNT(*) FROM intersected_stores)                             AS intersect_store_count,
    (SELECT COUNT(*) FROM excepted_customers)                             AS except_customer_count
FROM agg_store_sales agg
JOIN store s ON agg.ss_store_sk = s.s_store_sk
JOIN promotion p ON agg.ss_promo_sk = p.p_promo_sk
JOIN time_dim t ON agg.ss_sold_time_sk = t.t_time_sk
JOIN customer c ON agg.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON agg.ss_hdemo_sk = hd.hd_demo_sk
JOIN sampled_catalog_sales cs ON cs.cs_sold_time_sk = agg.ss_sold_time_sk
    AND cs.cs_bill_customer_sk = c.c_customer_sk
    AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    AND cs.cs_promo_sk = p.p_promo_sk
JOIN web_sales ws ON ws.ws_sold_time_sk = agg.ss_sold_time_sk
    AND ws.ws_bill_customer_sk = c.c_customer_sk
    AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    AND ws.ws_promo_sk = p.p_promo_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
LEFT JOIN agg_store_returns ret ON s.s_store_sk = ret.sr_store_sk
WHERE
    s.s_state = 'CA'
    AND p.p_channel_tv = 'N'
    AND hd.hd_income_band_sk = 5
    AND c.c_birth_year BETWEEN 1970 AND 1980
    AND wsite.web_company_id IN (3, 4)
    AND t.t_hour BETWEEN 9 AND 17
    AND cs.cs_ext_sales_price > 500
GROUP BY ROLLUP (s.s_state, p.p_promo_id, t.t_hour)
ORDER BY s.s_state, p.p_promo_id, t.t_hour
LIMIT 100
