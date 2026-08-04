WITH cs_sample AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
),
filtered_cs AS (
    SELECT *
    FROM cs_sample
    WHERE cs_ext_tax > 100
      AND cs_ext_ship_cost < 1000
),
stores_without_sales AS (
    SELECT s_store_sk
    FROM store
    EXCEPT
    SELECT ss_store_sk
    FROM store_sales
),
joined_data AS (
    SELECT
        ss.ss_store_sk,
        s.s_store_name,
        s.s_state,
        td.t_hour,
        td.t_shift,
        hd.hd_buy_potential,
        hd.hd_vehicle_count,
        r.r_reason_desc,
        wp.wp_type,
        wr.wr_return_amt,
        ss.ss_net_paid,
        filtered_cs.cs_net_paid_inc_ship_tax
    FROM store_sales ss
    FULL OUTER JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_time_sk = td.t_time_sk
    LEFT JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN filtered_cs
        ON filtered_cs.cs_sold_time_sk = td.t_time_sk
    WHERE s.s_state = 'CA'
      AND td.t_shift = 'first'
      AND hd.hd_vehicle_count BETWEEN 1 AND 3
),
agg AS (
    SELECT
        s_store_name,
        t_hour,
        hd_buy_potential,
        r_reason_desc,
        wp_type,
        COUNT(*) AS txn_count,
        SUM(ss_net_paid) AS sum_store_net_paid,
        SUM(cs_net_paid_inc_ship_tax) AS sum_catalog_net_paid,
        AVG(wr_return_amt) AS avg_return_amt,
        MIN(ss_net_paid) AS min_store_net_paid,
        MAX(ss_net_paid) AS max_store_net_paid
    FROM joined_data
    GROUP BY s_store_name, t_hour, hd_buy_potential, r_reason_desc, wp_type
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY sum_store_net_paid DESC) AS rn
    FROM agg
)
SELECT
    ranked.*, 
    (SELECT COUNT(*) FROM stores_without_sales) AS stores_without_sales_count
FROM ranked
WHERE rn <= 5
ORDER BY s_store_name, rn
LIMIT 100
