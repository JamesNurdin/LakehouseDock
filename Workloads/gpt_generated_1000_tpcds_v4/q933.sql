WITH joined AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_brand,
        i.i_color,
        s.s_state,
        cs.cs_net_paid,
        cs.cs_ext_sales_price,
        ss.ss_net_paid,
        ss.ss_coupon_amt,
        wp.wp_link_count,
        wp.wp_type
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
        AND ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#23'
      AND s.s_state = 'CA'
      AND ss.ss_coupon_amt > 1000
      AND cs.cs_ext_sales_price > 5000
      AND wp.wp_link_count BETWEEN 10 AND 30
      AND d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
)
SELECT
    d_year,
    i_brand,
    s_state,
    COUNT(*) AS transaction_cnt,
    SUM(cs_net_paid) AS total_catalog_net_paid,
    SUM(ss_net_paid) AS total_store_net_paid,
    AVG(ss_coupon_amt) AS avg_coupon_amt,
    MIN(cs_ext_sales_price) AS min_catalog_sales_price,
    MAX(ss_net_paid) AS max_store_net_paid
FROM joined
GROUP BY d_year, i_brand, s_state
HAVING (SUM(cs_net_paid) + SUM(ss_net_paid)) > 100000
ORDER BY total_catalog_net_paid DESC
LIMIT 100
