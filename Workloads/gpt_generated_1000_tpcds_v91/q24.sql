WITH part1 AS (
    SELECT
        hd.hd_income_band_sk,
        t.t_hour,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    CROSS JOIN LATERAL (
        SELECT t_hour, t_am_pm, t_time_id
        FROM time_dim td
        WHERE td.t_time_sk = ss.ss_sold_time_sk
    ) AS t
    WHERE
        hd.hd_vehicle_count >= 2
        AND hd.hd_buy_potential = '1001-5000'
        AND ss.ss_coupon_amt > (SELECT AVG(ss2.ss_coupon_amt) FROM store_sales ss2)
        AND t.t_am_pm = 'PM'
        AND t.t_hour BETWEEN 12 AND 18
        AND t.t_time_id IN ('AAAAAAAACBAAAAAA', 'AAAAAAAABAAAAAA')
    GROUP BY hd.hd_income_band_sk, t.t_hour
),
part2 AS (
    SELECT
        hd.hd_income_band_sk,
        t.t_hour,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    CROSS JOIN LATERAL (
        SELECT t_hour, t_am_pm, t_time_id
        FROM time_dim td
        WHERE td.t_time_sk = ss.ss_sold_time_sk
    ) AS t
    WHERE
        hd.hd_vehicle_count >= 3
        AND hd.hd_buy_potential = '>10000'
        AND ss.ss_coupon_amt > 1000.00
        AND t.t_am_pm = 'AM'
        AND t.t_hour BETWEEN 6 AND 11
        AND t.t_time_id IN ('AAAAAAAEBAAAAAA', 'AAAAAAAJAAAAAAA')
    GROUP BY hd.hd_income_band_sk, t.t_hour
),
unioned AS (
    SELECT * FROM part1
    UNION
    SELECT * FROM part2
)
SELECT
    u.t_hour,
    AVG(u.total_profit) AS avg_profit,
    SUM(u.total_sales) AS sum_sales,
    COUNT(DISTINCT u.hd_income_band_sk) AS income_band_count
FROM unioned u
GROUP BY u.t_hour
HAVING SUM(u.total_sales) > 5000.00
ORDER BY u.t_hour ASC
