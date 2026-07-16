WITH
sales_union AS (
    SELECT
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_quantity AS quantity,
        cs.cs_ext_sales_price AS ext_sales_price,
        cs.cs_ext_tax AS ext_tax,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_promo_sk AS promo_sk,
        'catalog' AS sales_channel
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_customer_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_ext_tax,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_promo_sk,
        'store' AS sales_channel
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_bill_customer_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_ext_tax,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_promo_sk,
        'web' AS sales_channel
    FROM web_sales ws
),
customer_latest_sales AS (
    SELECT
        su.customer_sk,
        MAX(d.d_date) AS latest_sale_date
    FROM sales_union su
    JOIN date_dim d ON su.sold_date_sk = d.d_date_sk
    GROUP BY su.customer_sk
),
promo_details AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        COALESCE(p.p_discount_active, 'N') AS discount_active
    FROM promotion p
),
customer_sales_summary AS (
    SELECT
        su.customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(su.ext_sales_price) AS total_sales,
        SUM(su.net_profit) AS total_profit,
        COUNT(*) AS transaction_count,
        AVG(su.ext_sales_price) AS avg_sale_price,
        SUM(CASE WHEN pd.discount_active = 'Y' THEN su.ext_sales_price * 0.9 ELSE su.ext_sales_price END) AS discounted_sales,
        array_join(array_agg(DISTINCT pd.p_promo_name), ', ') AS promos_used,
        MAX(d.d_year) AS latest_year
    FROM sales_union su
    LEFT JOIN customer c ON su.customer_sk = c.c_customer_sk
    LEFT JOIN date_dim d ON su.sold_date_sk = d.d_date_sk
    LEFT JOIN promo_details pd ON su.promo_sk = pd.p_promo_sk
    GROUP BY su.customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name
),
final_stats AS (
    SELECT
        cs.customer_sk,
        cs.c_customer_id,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.total_profit,
        cs.transaction_count,
        cs.avg_sale_price,
        cs.discounted_sales,
        cs.promos_used,
        cs.latest_year,
        CASE
            WHEN cs.total_profit > 0 THEN 'Profitable'
            WHEN cs.total_profit = 0 THEN 'Zero Profit'
            ELSE 'Loss'
        END AS profit_status,
        COALESCE(cls.latest_sale_date, DATE '1970-01-01') AS latest_sale_date,
        (SELECT COUNT(*)
         FROM store_returns sr
         JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
         WHERE sr.sr_customer_sk = cs.customer_sk AND d_sr.d_year = cs.latest_year) AS returns_in_latest_year,
        (SELECT COUNT(*)
         FROM web_returns wr
         JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
         WHERE wr.wr_refunded_customer_sk = cs.customer_sk AND d_wr.d_year = cs.latest_year) AS web_returns_in_latest_year,
        (SELECT COUNT(*)
         FROM catalog_returns cr
         JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
         WHERE cr.cr_returning_customer_sk = cs.customer_sk AND d_cr.d_year = cs.latest_year) AS catalog_returns_in_latest_year
    FROM customer_sales_summary cs
    LEFT JOIN customer_latest_sales cls ON cs.customer_sk = cls.customer_sk
    WHERE cs.total_sales > 1000
)
SELECT
    f.customer_sk,
    f.c_customer_id,
    CONCAT(f.c_first_name, ' ', f.c_last_name) AS full_name,
    f.total_sales,
    f.total_profit,
    f.transaction_count,
    f.avg_sale_price,
    f.discounted_sales,
    f.promos_used,
    f.latest_year,
    f.profit_status,
    f.latest_sale_date,
    f.returns_in_latest_year,
    f.web_returns_in_latest_year,
    f.catalog_returns_in_latest_year,
    CASE
        WHEN f.returns_in_latest_year + f.web_returns_in_latest_year + f.catalog_returns_in_latest_year > 0 THEN 'Has Returns'
        ELSE 'No Returns'
    END AS return_flag,
    ROW_NUMBER() OVER (ORDER BY f.total_sales DESC) AS sales_rank,
    RANK() OVER (PARTITION BY f.profit_status ORDER BY f.total_profit DESC) AS profit_rank_within_status,
    PERCENT_RANK() OVER (ORDER BY f.total_sales) AS sales_percentile,
    CONCAT('Y', CAST(f.latest_year AS VARCHAR)) AS year_code,
    COALESCE(NULLIF(f.promos_used, ''), 'No Promo') AS promo_summary,
    f.total_sales / NULLIF(f.transaction_count, 0) AS avg_sales_per_txn
FROM final_stats f
ORDER BY f.total_sales DESC
LIMIT 100
