WITH filtered_dates AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_year = 2000
),
fact_a AS (
    SELECT
        s.s_store_name AS store_name,
        cs.cs_ext_sales_price AS sales,
        cs.cs_order_number,
        c.c_customer_id,
        hd.hd_income_band_sk,
        i.inv_quantity_on_hand,
        ss.ss_net_profit,
        wp.wp_url,
        ws.web_name,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY cs.cs_ext_sales_price DESC) AS rn
    FROM catalog_sales cs
    JOIN filtered_dates d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    FULL OUTER JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    FULL OUTER JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE cs.cs_quantity > 2
),
fact_b AS (
    SELECT
        s.s_store_name AS store_name,
        cs.cs_ext_sales_price AS sales,
        cs.cs_order_number,
        c.c_customer_id,
        hd.hd_income_band_sk,
        i.inv_quantity_on_hand,
        ss.ss_net_profit,
        wp.wp_url,
        ws.web_name,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY cs.cs_ext_sales_price DESC) AS rn
    FROM catalog_sales cs
    JOIN filtered_dates d ON cs.cs_ship_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_ship_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE cs.cs_quantity <= 2
),
intersected AS (
    SELECT * FROM fact_a
    INTERSECT
    SELECT * FROM fact_b
),
union_facts AS (
    SELECT store_name, sales FROM fact_a
    UNION
    SELECT store_name, sales FROM fact_b
)
SELECT
    uf.store_name,
    SUM(uf.sales) AS total_sales,
    COUNT(DISTINCT i.cs_order_number) AS distinct_orders,
    MAX(i.rn) AS max_rn
FROM union_facts uf
JOIN intersected i ON uf.store_name = i.store_name
GROUP BY uf.store_name
HAVING SUM(uf.sales) > 10000
ORDER BY total_sales DESC
LIMIT 100
