WITH
    /* Catalog sales aggregated per customer and hour */
    cs_agg AS (
        SELECT
            cs.cs_bill_customer_sk AS customer_sk,
            cc.cc_name AS call_center_name,
            sm.sm_type AS ship_type,
            td.t_hour AS hour_of_day,
            SUM(cs.cs_net_paid_inc_tax) AS total_net_paid,
            COUNT(*) AS order_cnt,
            CASE WHEN SUM(cs.cs_ext_discount_amt) > 1000 THEN 'HIGH_DISC' ELSE 'LOW_DISC' END AS discount_level
        FROM
            catalog_sales cs
            JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
            JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
            JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
            JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        WHERE
            cc.cc_gmt_offset BETWEEN -5 AND 5
            AND cs.cs_list_price > 50
            AND cs.cs_quantity >= 1
            AND sm.sm_carrier = 'UPS'
            AND td.t_hour BETWEEN 8 AND 18
            AND c.c_preferred_cust_flag = 'Y'
            AND cc.cc_call_center_sk IN (
                SELECT cs2.cs_call_center_sk
                FROM catalog_sales cs2
                WHERE cs2.cs_net_paid_inc_tax > 2000
            )
        GROUP BY
            cs.cs_bill_customer_sk,
            cc.cc_name,
            sm.sm_type,
            td.t_hour
    ),
    /* Store sales aggregated per customer and hour */
    ss_agg AS (
        SELECT
            ss.ss_customer_sk AS customer_sk,
            td2.t_hour AS hour_of_day,
            SUM(ss.ss_net_paid) AS total_store_sales,
            COUNT(*) AS transaction_cnt,
            CASE WHEN SUM(ss.ss_coupon_amt) > 500 THEN 'HIGH_COUPON' ELSE 'LOW_COUPON' END AS coupon_level
        FROM
            store_sales ss
            JOIN time_dim td2 ON ss.ss_sold_time_sk = td2.t_time_sk
            JOIN customer c2 ON ss.ss_customer_sk = c2.c_customer_sk
        WHERE
            ss.ss_quantity > 0
            AND ss.ss_list_price BETWEEN 20 AND 200
            AND td2.t_hour BETWEEN 8 AND 18
            AND c2.c_preferred_cust_flag = 'Y'
            AND ss.ss_customer_sk IN (
                SELECT c3.c_customer_sk
                FROM customer c3
                WHERE c3.c_birth_year BETWEEN 1960 AND 1980
            )
            AND ss.ss_net_paid IS NOT NULL
            AND ss.ss_wholesale_cost > 0
        GROUP BY
            ss.ss_customer_sk,
            td2.t_hour
    ),
    /* Full outer join of the two aggregated streams */
    combined AS (
        SELECT
            COALESCE(cs.customer_sk, ss.customer_sk) AS customer_sk,
            cs.call_center_name,
            cs.ship_type,
            ss.hour_of_day,
            cs.hour_of_day AS cs_hour,
            cs.total_net_paid,
            ss.total_store_sales,
            cs.discount_level,
            ss.coupon_level
        FROM cs_agg cs
        FULL OUTER JOIN ss_agg ss
            ON cs.customer_sk = ss.customer_sk
            AND cs.hour_of_day = ss.hour_of_day
    ),
    /* Apply additional filters on the joined result */
    filtered_combined AS (
        SELECT *
        FROM combined
        WHERE (total_net_paid > 10000 OR total_store_sales > 5000)
            AND (discount_level = 'HIGH_DISC' OR coupon_level = 'HIGH_COUPON')
            AND customer_sk IS NOT NULL
            AND call_center_name IS NOT NULL
            AND hour_of_day BETWEEN 9 AND 17
            AND (total_net_paid + total_store_sales) > 15000
    ),
    /* Small dimension for a cross join */
    hour_vals AS (
        SELECT t_hour
        FROM time_dim
        WHERE t_hour IN (9, 12, 15)
    ),
    /* Final data set with cross join and a scalar sub‑query using EXCEPT */
    final AS (
        SELECT
            fc.customer_sk,
            fc.call_center_name,
            fc.hour_of_day,
            fc.total_net_paid,
            fc.total_store_sales,
            fc.discount_level,
            fc.coupon_level,
            hv.t_hour AS cross_hour,
            CASE WHEN fc.discount_level = 'HIGH_DISC'
                 THEN fc.total_net_paid * 1.10
                 ELSE fc.total_net_paid
            END AS adjusted_metric,
            /* scalar sub‑query: count of call‑center keys present in catalog_sales but missing in call_center */
            (SELECT COUNT(*) FROM (
                SELECT cs_call_center_sk FROM catalog_sales
                EXCEPT
                SELECT cc_call_center_sk FROM call_center
            ) AS diff) AS missing_call_center_cnt
        FROM filtered_combined fc
        CROSS JOIN hour_vals hv
        WHERE hv.t_hour = fc.hour_of_day
    )
SELECT
    customer_sk,
    call_center_name,
    hour_of_day,
    total_net_paid,
    total_store_sales,
    discount_level,
    coupon_level,
    cross_hour,
    adjusted_metric,
    missing_call_center_cnt
FROM final
ORDER BY total_net_paid DESC, total_store_sales DESC
LIMIT 100
