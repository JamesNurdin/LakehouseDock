WITH agg_cs AS (
    SELECT
        ca.ca_state AS state,
        d.d_year AS year,
        p.p_promo_name AS promo_name,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND hd.hd_dep_count = 0
      AND ca.ca_state = 'TX'
      AND w.w_state = 'CA'
      AND p.p_channel_tv = 'N'
    GROUP BY ca.ca_state, d.d_year, p.p_promo_name
),
agg_ss AS (
    SELECT
        ca2.ca_state AS state,
        d2.d_year AS year,
        p2.p_promo_name AS promo_name,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(*) AS order_cnt
    FROM store_sales ss
    JOIN date_dim d2 ON ss.ss_sold_date_sk = d2.d_date_sk
    JOIN promotion p2 ON ss.ss_promo_sk = p2.p_promo_sk
    JOIN customer_address ca2 ON ss.ss_addr_sk = ca2.ca_address_sk
    JOIN household_demographics hd2 ON ss.ss_hdemo_sk = hd2.hd_demo_sk
    WHERE d2.d_year = 2001
      AND hd2.hd_dep_count = 0
      AND ca2.ca_state = 'TX'
      AND p2.p_channel_tv = 'N'
    GROUP BY ca2.ca_state, d2.d_year, p2.p_promo_name
),
union_all AS (
    SELECT * FROM agg_cs
    UNION ALL
    SELECT * FROM agg_ss
)
SELECT
    state,
    year,
    promo_name,
    total_net_paid,
    order_cnt,
    ROW_NUMBER() OVER (PARTITION BY state ORDER BY total_net_paid DESC) AS state_rank,
    (SELECT MAX(p3.p_cost) FROM promotion p3 WHERE p3.p_channel_tv = 'N') AS max_tv_promo_cost
FROM union_all
ORDER BY total_net_paid DESC
LIMIT 100
