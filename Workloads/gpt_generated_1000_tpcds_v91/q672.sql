WITH
store_agg AS (
    SELECT
        ss.ss_customer_sk AS cust_sk,
        d.d_year,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        SUM(ss.ss_net_profit) AS store_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_txns,
        COUNT(DISTINCT ws.web_site_id) AS num_web_sites
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'MFGR#1'
      AND p.p_discount_active = 'Y'
      AND hd.hd_income_band_sk >= 5
      AND c.c_preferred_cust_flag = 'Y'
    GROUP BY ss.ss_customer_sk, d.d_year
),
catalog_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS cust_sk,
        d.d_year,
        SUM(cs.cs_ext_sales_price) AS catalog_sales,
        SUM(cs.cs_net_paid) AS catalog_paid,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'MFGR#1'
      AND p.p_discount_active = 'Y'
      AND hd.hd_income_band_sk >= 5
      AND c.c_preferred_cust_flag = 'Y'
    GROUP BY cs.cs_bill_customer_sk, d.d_year
),
returns_agg AS (
    SELECT
        wr.wr_refunded_customer_sk AS cust_sk,
        d.d_year,
        SUM(wr.wr_net_loss) AS total_returns,
        COUNT(*) AS return_count
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'MFGR#1'
      AND hd.hd_income_band_sk >= 5
      AND c.c_preferred_cust_flag = 'Y'
    GROUP BY wr.wr_refunded_customer_sk, d.d_year
),
combined AS (
    SELECT
        s.cust_sk,
        s.d_year,
        s.store_sales,
        s.store_profit,
        s.store_txns,
        s.num_web_sites,
        ca.catalog_sales,
        ca.catalog_paid,
        ca.catalog_orders,
        r.total_returns,
        r.return_count
    FROM store_agg s
    LEFT JOIN catalog_agg ca
        ON s.cust_sk = ca.cust_sk AND s.d_year = ca.d_year
    LEFT JOIN returns_agg r
        ON s.cust_sk = r.cust_sk AND s.d_year = r.d_year
),
high_rev AS (
    SELECT cust_sk, d_year
    FROM combined
    WHERE (coalesce(store_sales, 0) + coalesce(catalog_sales, 0) - coalesce(total_returns, 0)) > 200000
),
high_ret AS (
    SELECT cust_sk, d_year
    FROM combined
    WHERE coalesce(total_returns, 0) > 50000
),
filtered_customers AS (
    SELECT cust_sk, d_year
    FROM high_rev
    EXCEPT
    SELECT cust_sk, d_year FROM high_ret
)
SELECT
    c.cust_sk,
    c.d_year,
    c.store_sales,
    c.catalog_sales,
    coalesce(c.total_returns, 0) AS total_returns,
    (coalesce(c.store_sales, 0) + coalesce(c.catalog_sales, 0) - coalesce(c.total_returns, 0)) AS net_revenue,
    c.store_profit,
    c.store_txns,
    c.num_web_sites,
    c.catalog_orders,
    coalesce(c.return_count, 0) AS return_count
FROM combined c
JOIN filtered_customers fc
    ON c.cust_sk = fc.cust_sk AND c.d_year = fc.d_year
ORDER BY net_revenue DESC
LIMIT 100
