WITH male_sales AS (
    SELECT
        s.s_store_name AS store_name,
        cd.cd_gender AS gender,
        hd.hd_vehicle_count AS vehicle_count,
        sum(ss.ss_ext_sales_price) AS total_sales,
        sum(sr.sr_refunded_cash) AS total_returns,
        avg(ss.ss_ext_discount_amt) AS avg_discount,
        count(DISTINCT ss.ss_ticket_number) AS txn_count
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
        AND sr.sr_store_sk = s.s_store_sk
    WHERE cd.cd_gender = 'M'
      AND hd.hd_dep_count >= 5
      AND ss.ss_wholesale_cost > 30.00
    GROUP BY s.s_store_name, cd.cd_gender, hd.hd_vehicle_count
    HAVING sum(ss.ss_ext_sales_price) > 10000
),
female_sales AS (
    SELECT
        s.s_store_name AS store_name,
        cd.cd_gender AS gender,
        hd.hd_vehicle_count AS vehicle_count,
        sum(ss.ss_ext_sales_price) AS total_sales,
        sum(sr.sr_refunded_cash) AS total_returns,
        avg(ss.ss_ext_discount_amt) AS avg_discount,
        count(DISTINCT ss.ss_ticket_number) AS txn_count
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
        AND sr.sr_store_sk = s.s_store_sk
    WHERE cd.cd_gender = 'F'
      AND hd.hd_vehicle_count >= 2
      AND ss.ss_coupon_amt > 500.00
    GROUP BY s.s_store_name, cd.cd_gender, hd.hd_vehicle_count
    HAVING sum(ss.ss_ext_sales_price) > 15000
)
SELECT store_name,
       gender,
       vehicle_count,
       total_sales,
       total_returns,
       avg_discount,
       txn_count
FROM male_sales
UNION ALL
SELECT store_name,
       gender,
       vehicle_count,
       total_sales,
       total_returns,
       avg_discount,
       txn_count
FROM female_sales
ORDER BY store_name, gender, vehicle_count
