WITH
sales_data AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_brand,
        i.i_item_id,
        c.c_customer_id,
        CASE
            WHEN cs.cs_order_number IS NOT NULL THEN 'catalog'
            WHEN ss.ss_ticket_number IS NOT NULL THEN 'store'
            WHEN ws.ws_order_number IS NOT NULL THEN 'web'
            ELSE 'unknown'
        END AS sales_channel,
        COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0) + COALESCE(ws.ws_net_paid, 0) AS net_paid,
        COALESCE(cs.cs_net_profit, 0) + COALESCE(ss.ss_net_profit, 0) + COALESCE(ws.ws_net_profit, 0) AS net_profit,
        COALESCE(p.p_promo_name, 'No Promo') AS promo_name
    FROM date_dim d
    LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN item i ON i.i_item_sk = COALESCE(cs.cs_item_sk, ss.ss_item_sk, ws.ws_item_sk)
    LEFT JOIN customer c ON c.c_customer_sk = COALESCE(cs.cs_bill_customer_sk, ss.ss_customer_sk, ws.ws_bill_customer_sk)
    LEFT JOIN promotion p ON p.p_promo_sk = COALESCE(cs.cs_promo_sk, ss.ss_promo_sk, ws.ws_promo_sk)
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND (cs.cs_order_number IS NOT NULL OR ss.ss_ticket_number IS NOT NULL OR ws.ws_order_number IS NOT NULL)
),
returns_data AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_brand,
        COALESCE(cr.cr_return_amount, 0) AS catalog_return_amount,
        COALESCE(sr.sr_return_amt, 0) AS store_return_amount,
        COALESCE(wr.wr_return_amt, 0) AS web_return_amount
    FROM date_dim d
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN item i ON i.i_item_sk = COALESCE(cr.cr_item_sk, sr.sr_item_sk, wr.wr_item_sk)
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND (cr.cr_order_number IS NOT NULL OR sr.sr_ticket_number IS NOT NULL OR wr.wr_order_number IS NOT NULL)
),
aggregated AS (
    SELECT
        s.d_year,
        s.d_month_seq,
        s.i_category,
        s.i_brand,
        SUM(s.net_paid) AS total_net_paid,
        SUM(s.net_profit) AS total_net_profit,
        SUM(COALESCE(r.catalog_return_amount,0) + COALESCE(r.store_return_amount,0) + COALESCE(r.web_return_amount,0)) AS total_return_amount,
        SUM(s.net_paid) - SUM(COALESCE(r.catalog_return_amount,0) + COALESCE(r.store_return_amount,0) + COALESCE(r.web_return_amount,0)) AS net_sales,
        SUM(s.net_profit) - (SUM(COALESCE(r.catalog_return_amount,0) + COALESCE(r.store_return_amount,0) + COALESCE(r.web_return_amount,0)) * 0.2) AS adjusted_net_profit,
        approx_distinct(s.c_customer_id) AS approx_distinct_customers,
        COUNT(*) AS total_transactions,
        approx_percentile(s.net_paid, 0.5) AS median_net_paid,
        SUM(CASE WHEN s.sales_channel = 'catalog' THEN 1 ELSE 0 END) AS catalog_sales_count,
        SUM(CASE WHEN s.sales_channel = 'store' THEN 1 ELSE 0 END) AS store_sales_count,
        SUM(CASE WHEN s.sales_channel = 'web' THEN 1 ELSE 0 END) AS web_sales_count
    FROM sales_data s
    LEFT JOIN returns_data r
      ON r.d_year = s.d_year
     AND r.d_month_seq = s.d_month_seq
     AND r.i_category = s.i_category
     AND r.i_brand = s.i_brand
    GROUP BY GROUPING SETS (
        (s.d_year, s.d_month_seq, s.i_category, s.i_brand),
        (s.d_year, s.i_category, s.i_brand),
        (s.i_category, s.i_brand),
        (s.i_category)
    )
)
SELECT
    a.d_year,
    a.d_month_seq,
    a.i_category,
    a.i_brand,
    a.total_net_paid,
    a.total_net_profit,
    a.total_return_amount,
    a.net_sales,
    a.adjusted_net_profit,
    a.approx_distinct_customers,
    a.total_transactions,
    a.median_net_paid,
    a.catalog_sales_count,
    a.store_sales_count,
    a.web_sales_count,
    CASE WHEN a.total_transactions > 0 THEN CAST(a.catalog_sales_count AS double) / a.total_transactions END AS catalog_sales_ratio,
    CASE WHEN a.total_transactions > 0 THEN CAST(a.store_sales_count AS double) / a.total_transactions END AS store_sales_ratio,
    CASE WHEN a.total_transactions > 0 THEN CAST(a.web_sales_count AS double) / a.total_transactions END AS web_sales_ratio,
    CASE WHEN a.total_net_paid > 0 THEN a.adjusted_net_profit / a.total_net_paid END AS profit_to_sales_ratio,
    RANK() OVER (PARTITION BY a.d_year ORDER BY a.net_sales DESC) AS year_rank
FROM aggregated a
WHERE a.total_net_paid IS NOT NULL
ORDER BY a.d_year DESC, a.net_sales DESC
LIMIT 200
