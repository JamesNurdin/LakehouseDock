WITH sampled_cs AS (
        SELECT
            cs_sold_date_sk,
            cs_sold_time_sk,
            cs_ship_mode_sk,
            cs_call_center_sk,
            cs_bill_customer_sk,
            cs_bill_cdemo_sk,
            cs_bill_addr_sk,
            cs_catalog_page_sk,
            cs_ext_sales_price,
            cs_net_profit,
            cs_order_number
        FROM catalog_sales
        TABLESAMPLE BERNOULLI (10)
    ),
    joined1 AS (
        SELECT
            cs.cs_order_number,
            cs.cs_bill_customer_sk AS bill_customer_sk,
            cs.cs_ship_mode_sk,
            cs.cs_catalog_page_sk,
            cs.cs_call_center_sk,
            cs.cs_sold_time_sk,
            cs.cs_ext_sales_price,
            cs.cs_net_profit,
            c.c_first_name,
            c.c_last_name,
            ca.ca_city,
            cd.cd_credit_rating,
            sm.sm_type,
            tp.t_hour,
            tp.t_shift,
            cp.cp_department,
            cc.cc_name
        FROM sampled_cs cs
        JOIN customer c
            ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_address ca
            ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd
            ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN ship_mode sm
            ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN time_dim tp
            ON cs.cs_sold_time_sk = tp.t_time_sk
        JOIN catalog_page cp
            ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN call_center cc
            ON cs.cs_call_center_sk = cc.cc_call_center_sk
    ),
    full_joined AS (
        SELECT
            j1.cs_ext_sales_price,
            j1.cs_net_profit,
            j1.cs_order_number,
            j1.bill_customer_sk,
            j1.c_first_name,
            j1.c_last_name,
            j1.ca_city,
            j1.cd_credit_rating,
            j1.sm_type AS sm_type_primary,
            sm2.sm_type AS sm_type_secondary,
            j1.t_hour,
            j1.t_shift,
            j1.cp_department,
            j1.cc_name
        FROM joined1 j1
        FULL OUTER JOIN ship_mode sm2
            ON j1.cs_ship_mode_sk = sm2.sm_ship_mode_sk
    ),
    agg1 AS (
        SELECT
            bill_customer_sk,
            c_first_name,
            c_last_name,
            ca_city,
            cd_credit_rating,
            SUM(cs_ext_sales_price) AS total_sales,
            AVG(cs_net_profit) AS avg_profit,
            COUNT(*) AS num_orders
        FROM full_joined
        WHERE cc_name IS NOT NULL                     -- filter 1 (ensures match on call_center side)
          AND cd_credit_rating <> 'Low Risk'          -- filter 2
          AND t_hour BETWEEN 10 AND 18               -- filter 3
        GROUP BY
            bill_customer_sk,
            c_first_name,
            c_last_name,
            ca_city,
            cd_credit_rating
    ),
    union_branch AS (
        SELECT
            ws.ws_bill_customer_sk AS bill_customer_sk,
            c.c_first_name,
            c.c_last_name,
            ca.ca_city,
            cd.cd_credit_rating,
            ws.ws_ext_sales_price AS total_sales,
            ws.ws_net_profit AS avg_profit,
            1 AS num_orders
        FROM web_sales ws
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        WHERE ws.ws_ext_sales_price > 1000                                 -- filter 4
          AND cd.cd_credit_rating = 'Good'                                 -- filter 5
          AND ws.ws_ship_mode_sk IN (
                SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_type = 'AIR'
          )
    ),
    combined AS (
        SELECT * FROM agg1
        UNION
        SELECT
            bill_customer_sk,
            c_first_name,
            c_last_name,
            ca_city,
            cd_credit_rating,
            total_sales,
            avg_profit,
            num_orders
        FROM union_branch
    ),
    final_agg AS (
        SELECT
            bill_customer_sk,
            c_first_name,
            c_last_name,
            ca_city,
            cd_credit_rating,
            SUM(total_sales) AS sum_sales,
            AVG(avg_profit) AS avg_profit_overall,
            SUM(num_orders) AS total_orders
        FROM combined
        GROUP BY
            bill_customer_sk,
            c_first_name,
            c_last_name,
            ca_city,
            cd_credit_rating
    ),
    ranked AS (
        SELECT
            bill_customer_sk,
            c_first_name,
            c_last_name,
            ca_city,
            cd_credit_rating,
            sum_sales,
            avg_profit_overall,
            total_orders,
            ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY sum_sales DESC) AS rnk
        FROM final_agg
        WHERE sum_sales > 5000                      -- filter 6
    )
SELECT
    bill_customer_sk,
    c_first_name,
    c_last_name,
    ca_city,
    cd_credit_rating,
    sum_sales,
    avg_profit_overall,
    total_orders
FROM ranked
WHERE rnk <= 5                                    -- keep top‑5 per city
ORDER BY ca_city, rnk
LIMIT 100
