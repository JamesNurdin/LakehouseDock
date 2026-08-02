WITH distinct_customers AS (
    SELECT DISTINCT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_birth_year
    FROM customer c
    WHERE c.c_birth_year BETWEEN 1960 AND 1980
),

sales_agg AS (
    SELECT
        dc.c_customer_id,
        cd.cd_gender,
        cd.cd_education_status,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(ws.ws_net_profit) AS web_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
        MIN(d_cs.d_date) AS first_sale_date,
        MAX(d_cs.d_date) AS last_sale_date
    FROM distinct_customers dc
    JOIN catalog_sales cs
        ON cs.cs_bill_customer_sk = dc.c_customer_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_cs
        ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN time_dim t_cs
        ON cs.cs_sold_time_sk = t_cs.t_time_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN store_returns sr
        ON sr.sr_customer_sk = dc.c_customer_sk
    JOIN time_dim t_sr
        ON sr.sr_return_time_sk = t_sr.t_time_sk
    JOIN date_dim d_sr
        ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN web_sales ws
        ON ws.ws_bill_customer_sk = dc.c_customer_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_ws
        ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN time_dim t_ws
        ON ws.ws_sold_time_sk = t_ws.t_time_sk
    WHERE
        d_cs.d_year = 2001
        AND t_cs.t_hour BETWEEN 8 AND 17
        AND cp.cp_department = 'Books'
        AND sr.sr_return_quantity > 0
        AND cd.cd_education_status = 'Secondary'
        AND EXISTS (
            SELECT 1
            FROM web_returns wr
            WHERE wr.wr_order_number = ws.ws_order_number
              AND wr.wr_returned_date_sk = d_ws.d_date_sk
        )
    GROUP BY
        dc.c_customer_id,
        cd.cd_gender,
        cd.cd_education_status
)
SELECT
    c_customer_id,
    cd_gender,
    cd_education_status,
    catalog_net_profit,
    web_net_profit,
    catalog_order_cnt,
    web_order_cnt,
    (catalog_net_profit + web_net_profit) AS total_net_profit,
    ROW_NUMBER() OVER (ORDER BY (catalog_net_profit + web_net_profit) DESC) AS profit_rank
FROM sales_agg
WHERE (catalog_net_profit + web_net_profit) > 5000
ORDER BY profit_rank
