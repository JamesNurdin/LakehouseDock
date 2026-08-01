WITH sales_sample AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
),
eligible_store_ids AS (
    SELECT s_store_sk
    FROM store
    WHERE s_floor_space > 9000000
    EXCEPT
    SELECT s_store_sk
    FROM store
    WHERE s_floor_space < 8000000
),
joined_data AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        ca.ca_zip,
        hd.hd_vehicle_count,
        ss.ss_sales_price,
        ss.ss_net_paid_inc_tax,
        ss.ss_quantity
    FROM sales_sample ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE s.s_store_sk IN (SELECT s_store_sk FROM eligible_store_ids)
      AND s.s_floor_space > 8000000
      AND hd.hd_vehicle_count >= 2
      AND ca.ca_zip = '40587'
      AND NOT EXISTS (
          SELECT 1
          FROM store_sales ss2
          WHERE ss2.ss_store_sk = s.s_store_sk
            AND ss2.ss_quantity = 0
      )
      AND ss.ss_sales_price > (
          SELECT AVG(ss3.ss_sales_price)
          FROM store_sales ss3
          WHERE ss3.ss_store_sk = s.s_store_sk
      )
)
SELECT
    jd.s_store_id,
    jd.s_store_name,
    jd.s_state,
    COUNT(*) AS sales_transactions,
    SUM(jd.ss_net_paid_inc_tax) AS total_net_paid_inc_tax,
    AVG(jd.ss_sales_price) AS avg_sales_price,
    MAX(jd.ss_sales_price) AS max_sales_price,
    (SELECT SUM(ss_all.ss_net_paid_inc_tax)
     FROM store_sales ss_all
     WHERE ss_all.ss_store_sk = jd.s_store_sk) AS total_net_paid_all_time
FROM joined_data jd
GROUP BY
    jd.s_store_id,
    jd.s_store_name,
    jd.s_state,
    jd.s_store_sk
ORDER BY total_net_paid_inc_tax DESC
LIMIT 100
