WITH joined AS (
    SELECT
        c.c_customer_id,
        ca.ca_state,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        p.p_promo_name,
        sm.sm_carrier,
        sm.sm_contract,
        sr.sr_return_amt,
        wr.wr_return_amt,
        wp.wp_char_count
    FROM customer c
    JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    LEFT JOIN web_returns wr
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
           AND wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE
        sm.sm_carrier IN ('UPS', 'FEDEX')
        AND p.p_discount_active = 'Y'
        AND ca.ca_state = 'CA'
        AND cs.cs_ext_sales_price > 100
),
agg AS (
    SELECT
        c_customer_id,
        ca_state,
        COUNT(DISTINCT cs_ext_sales_price) AS num_sales,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_net_profit) AS total_profit,
        SUM(COALESCE(sr_return_amt, 0)) AS total_store_return,
        SUM(COALESCE(wr_return_amt, 0)) AS total_web_return,
        COUNT(DISTINCT p_promo_name) AS promo_cnt,
        COUNT(DISTINCT sm_carrier) AS carrier_cnt,
        SUM(CASE WHEN wp_char_count > 1500 THEN 1 ELSE 0 END) AS high_char_pages
    FROM joined
    GROUP BY c_customer_id, ca_state
)
SELECT
    c_customer_id,
    ca_state,
    total_sales,
    total_profit,
    total_store_return,
    total_web_return,
    promo_cnt,
    carrier_cnt,
    high_char_pages,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank,
    ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY total_profit DESC) AS state_profit_rownum
FROM agg
WHERE total_sales > 0
ORDER BY sales_rank
LIMIT 100
