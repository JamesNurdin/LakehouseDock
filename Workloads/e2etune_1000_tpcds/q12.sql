WITH base AS (
    SELECT
        cc.cc_name AS call_center_name,
        d.d_year,
        hd.hd_buy_potential,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_quantity) AS avg_quantity,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        AVG(COALESCE(pages.pages_accessed, 0)) AS avg_pages_per_customer
    FROM
        catalog_sales cs
    JOIN
        call_center cc
            ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN
        date_dim d
            ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN
        customer c
            ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN
        household_demographics hd
            ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN (
        SELECT
            wp.wp_customer_sk AS customer_sk,
            d2.d_year,
            COUNT(DISTINCT wp.wp_web_page_sk) AS pages_accessed
        FROM
            web_page wp
        JOIN
            date_dim d2
                ON wp.wp_access_date_sk = d2.d_date_sk
        WHERE
            wp.wp_type = 'product'
        GROUP BY
            wp.wp_customer_sk,
            d2.d_year
    ) pages
        ON c.c_customer_sk = pages.customer_sk
        AND d.d_year = pages.d_year
    WHERE
        cc.cc_division = 3
        AND cc.cc_city = 'Greenwood'
        AND d.d_year = 2001
        AND hd.hd_income_band_sk BETWEEN 2 AND 4
    GROUP BY
        cc.cc_name,
        d.d_year,
        hd.hd_buy_potential
    HAVING
        SUM(cs.cs_net_profit) > 10000
)
SELECT
    call_center_name,
    d_year,
    hd_buy_potential,
    total_net_profit,
    avg_quantity,
    distinct_orders,
    avg_pages_per_customer,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank
FROM
    base
ORDER BY
    total_net_profit DESC
LIMIT 20
