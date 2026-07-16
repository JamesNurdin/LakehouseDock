WITH recent_customer_orders AS (
    SELECT
        c.c_customer_sk,
        MAX(d.d_date) AS last_order_date
    FROM customer c
    LEFT JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY c.c_customer_sk
),
sales_union AS (
    SELECT
        'store' AS sales_channel,
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_store_sk AS location_sk,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        CAST(NULL AS integer) AS call_center_sk,
        CAST(NULL AS integer) AS catalog_page_sk,
        CAST(NULL AS integer) AS web_page_sk
    FROM store_sales ss
    UNION ALL
    SELECT
        'catalog' AS sales_channel,
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_call_center_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        CAST(NULL AS integer)
    FROM catalog_sales cs
    UNION ALL
    SELECT
        'web' AS sales_channel,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_web_page_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        CAST(NULL AS integer),
        CAST(NULL AS integer),
        ws.ws_web_page_sk
    FROM web_sales ws
),
base_agg AS (
    SELECT
        su.sales_channel,
        su.customer_sk,
        d.d_year,
        SUM(su.net_paid) AS total_paid,
        SUM(su.net_profit) AS total_profit,
        COUNT(*) AS order_count,
        COALESCE(MAX(p.p_discount_active), 'N') AS any_discount_active
    FROM sales_union su
    LEFT JOIN date_dim d ON su.date_sk IS NOT DISTINCT FROM d.d_date_sk
    LEFT JOIN promotion p ON p.p_item_sk = su.item_sk
        AND d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    GROUP BY ROLLUP(su.sales_channel, su.customer_sk, d.d_year)
),
customer_rankings AS (
    SELECT
        ba.sales_channel,
        ba.customer_sk,
        ba.d_year,
        ba.total_paid,
        ba.total_profit,
        ba.order_count,
        ba.any_discount_active,
        ROW_NUMBER() OVER (PARTITION BY ba.sales_channel, ba.d_year ORDER BY ba.total_paid DESC) AS revenue_rank,
        RANK() OVER (PARTITION BY ba.sales_channel ORDER BY ba.total_profit DESC) AS profit_rank,
        CASE
            WHEN ba.total_profit > 0 THEN 'POSITIVE'
            WHEN ba.total_profit < 0 THEN 'NEGATIVE'
            ELSE 'ZERO'
        END AS profit_category
    FROM base_agg ba
    WHERE ba.sales_channel IS NOT NULL
),
final_agg AS (
    SELECT
        cr.sales_channel,
        cr.customer_sk,
        cr.d_year,
        cr.total_paid,
        cr.total_profit,
        cr.order_count,
        cr.revenue_rank,
        cr.profit_rank,
        cr.profit_category,
        cr.any_discount_active,
        CASE
            WHEN cr.revenue_rank = 1 THEN 'TOP'
            WHEN cr.revenue_rank <= 10 THEN 'TOP10'
            ELSE 'OTHERS'
        END AS rank_bucket,
        COALESCE(rc.last_order_date, DATE '1900-01-01') AS last_order_date,
        CONCAT('CUST_', CAST(cr.customer_sk AS VARCHAR)) AS customer_key,
        LENGTH(CONCAT(cr.sales_channel, '-', CASE WHEN cr.profit_category = 'POSITIVE' THEN 'G' ELSE 'B' END)) AS key_length,
        (cr.total_paid - cr.total_profit) / NULLIF(cr.total_paid, 0) AS loss_ratio,
        CASE
            WHEN rc.last_order_date IS NOT NULL
                AND EXISTS (
                    SELECT 1 FROM store_returns sr
                    JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
                    WHERE sr.sr_customer_sk = cr.customer_sk
                      AND dr.d_date > rc.last_order_date - INTERVAL '30' DAY
                )
            THEN TRUE
            ELSE FALSE
        END AS has_recent_return
    FROM customer_rankings cr
    LEFT JOIN recent_customer_orders rc ON rc.c_customer_sk = cr.customer_sk
    WHERE (cr.total_paid IS NOT NULL AND cr.total_paid > 0)
      AND (cr.profit_category <> 'ZERO' OR cr.total_profit IS NULL)
      AND (cr.any_discount_active = 'Y' OR cr.any_discount_active IS NULL)
)
SELECT
    f.sales_channel,
    f.d_year,
    COUNT(DISTINCT f.customer_sk) AS distinct_customers,
    SUM(f.total_paid) AS sum_total_paid,
    SUM(f.total_profit) AS sum_total_profit,
    AVG(f.loss_ratio) AS avg_loss_ratio,
    MAX(f.last_order_date) AS most_recent_order,
    array_join(array_agg(DISTINCT f.rank_bucket ORDER BY f.rank_bucket), ',') AS rank_buckets,
    MIN(f.key_length) AS min_key_len,
    MAX(f.key_length) AS max_key_len,
    COUNT(*) FILTER (WHERE f.profit_category = 'POSITIVE') AS pos_customers,
    COUNT(*) FILTER (WHERE f.profit_category = 'NEGATIVE') AS neg_customers,
    COUNT(*) FILTER (WHERE f.profit_category = 'ZERO' OR f.profit_category IS NULL) AS zero_customers,
    COUNT(*) FILTER (WHERE f.has_recent_return) AS customers_with_recent_return,
    SUM(CASE WHEN f.has_recent_return THEN f.total_paid ELSE 0 END) AS total_paid_recent_return_customers,
    MAX(CASE WHEN f.has_recent_return THEN f.last_order_date END) AS latest_return_date
FROM final_agg f
GROUP BY GROUPING SETS ((sales_channel, d_year), (sales_channel), ())
HAVING SUM(f.total_paid) > 0
ORDER BY sales_channel NULLS LAST, d_year NULLS LAST
