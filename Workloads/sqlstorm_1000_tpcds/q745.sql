WITH date_range AS (
    SELECT d_date_sk, d_year, d_date
    FROM date_dim
    WHERE d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
),
sales_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        dd.d_year,
        SUM(COALESCE(ss.ss_ext_sales_price, 0)) AS store_sales,
        SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS web_sales,
        SUM(COALESCE(cs.cs_ext_sales_price, 0)) AS catalog_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_txns,
        COUNT(DISTINCT ws.ws_order_number) AS web_txns,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_txns
    FROM customer c
    LEFT JOIN date_range dd
        ON (c.c_first_sales_date_sk = dd.d_date_sk OR c.c_first_shipto_date_sk = dd.d_date_sk)
    LEFT JOIN store_sales ss
        ON c.c_customer_sk = ss.ss_customer_sk AND ss.ss_sold_date_sk = dd.d_date_sk
    LEFT JOIN web_sales ws
        ON c.c_customer_sk = ws.ws_bill_customer_sk AND ws.ws_sold_date_sk = dd.d_date_sk
    LEFT JOIN catalog_sales cs
        ON c.c_customer_sk = cs.cs_bill_customer_sk AND cs.cs_sold_date_sk = dd.d_date_sk
    GROUP BY c.c_customer_sk, c.c_customer_id, dd.d_year
),
returns_agg AS (
    SELECT
        c.c_customer_sk,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS store_return_loss,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS web_return_loss,
        SUM(COALESCE(cr.cr_net_loss, 0)) AS catalog_return_loss
    FROM customer c
    LEFT JOIN store_returns sr
        ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN web_returns wr
        ON c.c_customer_sk = wr.wr_refunded_customer_sk
    LEFT JOIN catalog_returns cr
        ON c.c_customer_sk = cr.cr_refunded_customer_sk
    GROUP BY c.c_customer_sk
),
customer_score AS (
    SELECT
        s.c_customer_sk,
        s.c_customer_id,
        s.d_year,
        (s.store_sales + s.web_sales + s.catalog_sales) AS total_sales,
        COALESCE(r.store_return_loss, 0) + COALESCE(r.web_return_loss, 0) + COALESCE(r.catalog_return_loss, 0) AS total_returns,
        ((s.store_sales + s.web_sales + s.catalog_sales) - (COALESCE(r.store_return_loss, 0) + COALESCE(r.web_return_loss, 0) + COALESCE(r.catalog_return_loss, 0)))
            / NULLIF((s.store_sales + s.web_sales + s.catalog_sales), 0) AS net_margin,
        ROW_NUMBER() OVER (PARTITION BY s.d_year ORDER BY (s.store_sales + s.web_sales + s.catalog_sales) DESC) AS sales_rank,
        CASE 
            WHEN c.c_preferred_cust_flag = 'Y' THEN 'Preferred'
            WHEN s.store_sales > 0 AND s.web_sales = 0 THEN 'StoreOnly'
            WHEN s.store_sales = 0 AND s.web_sales > 0 THEN 'WebOnly'
            ELSE 'Mixed'
        END AS customer_type,
        CONCAT('CUST-', c.c_customer_id) AS cust_key,
        LENGTH(TRIM(COALESCE(c.c_email_address, ''))) AS email_len,
        CASE WHEN (s.store_sales + s.web_sales + s.catalog_sales) > 100000 THEN 1 ELSE 0 END AS high_spender_flag
    FROM sales_agg s
    LEFT JOIN returns_agg r ON s.c_customer_sk = r.c_customer_sk
    LEFT JOIN customer c ON s.c_customer_sk = c.c_customer_sk
    WHERE (s.store_sales + s.web_sales + s.catalog_sales) > 0
),
top_customers AS (
    SELECT *
    FROM customer_score
    WHERE sales_rank <= 10
),
item_sales AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        SUM(COALESCE(ss.ss_ext_sales_price, 0)) AS store_sales,
        SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS web_sales,
        SUM(COALESCE(cs.cs_ext_sales_price, 0)) AS catalog_sales
    FROM item i
    LEFT JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    GROUP BY i.i_item_sk, i.i_product_name, i.i_category, i.i_brand
)
SELECT 
    tc.cust_key,
    tc.c_customer_id,
    tc.d_year,
    tc.total_sales,
    tc.total_returns,
    ROUND(tc.net_margin * 100, 2) AS net_margin_pct,
    tc.customer_type,
    tc.email_len,
    tc.high_spender_flag,
    CASE 
        WHEN tc.cust_key IN (SELECT CONCAT('CUST-', c2.c_customer_id) FROM customer c2 WHERE c2.c_birth_year < 1950) THEN 'Silver'
        ELSE 'Gold'
    END AS loyalty_tier,
    CASE 
        WHEN tc.sales_rank = 1 THEN 'Champion'
        WHEN tc.sales_rank <= 5 THEN 'RunnerUp'
        ELSE 'Contender'
    END AS rank_label,
    i.i_product_name,
    i.i_category,
    i.i_brand,
    i.store_sales + i.web_sales + i.catalog_sales AS item_total_sales,
    ROW_NUMBER() OVER (PARTITION BY tc.cust_key ORDER BY i.store_sales + i.web_sales + i.catalog_sales DESC) AS item_rank
FROM top_customers tc
LEFT JOIN (
    SELECT i.*
    FROM item_sales i
    WHERE i.store_sales + i.web_sales + i.catalog_sales > 5000
    ORDER BY (i.store_sales + i.web_sales + i.catalog_sales) DESC
    LIMIT 5
) i ON TRUE
WHERE (tc.high_spender_flag = 1 AND i.i_item_sk IS NOT NULL) OR tc.high_spender_flag = 0

UNION ALL

SELECT 
    'TOTAL' AS cust_key,
    NULL AS c_customer_id,
    NULL AS d_year,
    SUM(total_sales) OVER () AS total_sales,
    SUM(total_returns) OVER () AS total_returns,
    NULL AS net_margin_pct,
    NULL AS customer_type,
    NULL AS email_len,
    NULL AS high_spender_flag,
    NULL AS loyalty_tier,
    NULL AS rank_label,
    NULL AS i_product_name,
    NULL AS i_category,
    NULL AS i_brand,
    NULL AS item_total_sales,
    NULL AS item_rank
FROM top_customers
ORDER BY total_sales DESC NULLS LAST, item_rank
