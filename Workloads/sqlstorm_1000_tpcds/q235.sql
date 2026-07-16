WITH sales_by_channel AS (
    SELECT 'store' AS channel,
           ss.ss_sold_date_sk AS sold_date_sk,
           ss.ss_item_sk,
           ss.ss_quantity,
           ss.ss_net_paid AS net_paid,
           ss.ss_net_profit AS net_profit,
           ss.ss_store_sk AS location_sk,
           ss.ss_ticket_number AS ticket_number
    FROM store_sales ss
    UNION ALL
    SELECT 'catalog' AS channel,
           cs.cs_sold_date_sk,
           cs.cs_item_sk,
           cs.cs_quantity,
           cs.cs_net_paid,
           cs.cs_net_profit,
           cs.cs_call_center_sk,
           cs.cs_order_number
    FROM catalog_sales cs
    UNION ALL
    SELECT 'web' AS channel,
           ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_quantity,
           ws.ws_net_paid,
           ws.ws_net_profit,
           ws.ws_web_page_sk,
           ws.ws_order_number
    FROM web_sales ws
),
returns_by_channel AS (
    SELECT 'store' AS channel,
           sr.sr_returned_date_sk AS returned_date_sk,
           sr.sr_item_sk,
           sr.sr_return_quantity,
           sr.sr_refunded_cash AS refunded_cash,
           sr.sr_store_sk AS location_sk,
           sr.sr_ticket_number AS ticket_number
    FROM store_returns sr
    UNION ALL
    SELECT 'catalog' AS channel,
           cr.cr_returned_date_sk,
           cr.cr_item_sk,
           cr.cr_return_quantity,
           cr.cr_refunded_cash,
           cr.cr_call_center_sk,
           cr.cr_order_number
    FROM catalog_returns cr
    UNION ALL
    SELECT 'web' AS channel,
           wr.wr_returned_date_sk,
           wr.wr_item_sk,
           wr.wr_return_quantity,
           wr.wr_refunded_cash,
           wr.wr_web_page_sk,
           wr.wr_order_number
    FROM web_returns wr
),
sales_aggr AS (
    SELECT
        s.channel,
        COALESCE(d.d_year, 0) AS year,
        s.location_sk,
        SUM(s.net_paid) AS total_sales,
        SUM(s.net_profit) AS total_profit,
        SUM(CASE WHEN s.net_paid IS NULL THEN 1 ELSE 0 END) AS null_sales_cnt,
        ROW_NUMBER() OVER (PARTITION BY s.channel ORDER BY SUM(s.net_paid) DESC) AS sales_rank,
        MAX(CASE WHEN s.net_paid IS NULL THEN 1 ELSE 0 END) AS has_null_sales
    FROM sales_by_channel s
    LEFT JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
    GROUP BY s.channel, COALESCE(d.d_year, 0), s.location_sk
),
return_aggr AS (
    SELECT
        r.channel,
        COALESCE(d.d_year, 0) AS year,
        r.location_sk,
        SUM(r.refunded_cash) AS total_refund,
        SUM(CASE WHEN r.refunded_cash IS NULL THEN 1 ELSE 0 END) AS null_refund_cnt
    FROM returns_by_channel r
    LEFT JOIN date_dim d ON r.returned_date_sk = d.d_date_sk
    GROUP BY r.channel, COALESCE(d.d_year, 0), r.location_sk
),
joined_metrics AS (
    SELECT
        sa.channel,
        sa.year,
        sa.location_sk,
        sa.total_sales,
        sa.total_profit,
        ra.total_refund,
        sa.sales_rank,
        sa.has_null_sales,
        CASE
            WHEN sa.total_sales = 0 THEN NULL
            ELSE sa.total_profit / sa.total_sales
        END AS profit_margin,
        COALESCE(NULLIF(ra.total_refund, 0), sa.total_sales) AS adjusted_sales,
        CONCAT('LOC_', LPAD(CAST(sa.location_sk AS VARCHAR), 8, '0')) AS loc_key,
        ROW_NUMBER() OVER (PARTITION BY sa.channel ORDER BY sa.total_profit DESC) AS profit_rank
    FROM sales_aggr sa
    LEFT JOIN return_aggr ra
      ON sa.channel = ra.channel
     AND sa.year = ra.year
     AND sa.location_sk = ra.location_sk
),
call_center_stats AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        COALESCE(AVG(cs.cs_net_profit), 0) AS avg_profit,
        CASE WHEN cc.cc_employees = 0 THEN NULL ELSE cc.cc_employees END AS employees,
        COALESCE(cc.cc_tax_percentage, 5.00) AS tax_pct
    FROM call_center cc
    LEFT JOIN catalog_sales cs ON cc.cc_call_center_sk = cs.cs_call_center_sk
    GROUP BY cc.cc_call_center_sk, cc.cc_name, cc.cc_employees, cc.cc_tax_percentage
)
SELECT
    jm.channel,
    jm.year,
    COALESCE(ccs.cc_name, 'UNKNOWN') AS call_center_name,
    jm.location_sk,
    jm.total_sales,
    jm.total_profit,
    jm.total_refund,
    jm.sales_rank,
    jm.profit_rank,
    jm.profit_margin,
    jm.adjusted_sales,
    jm.loc_key,
    CASE WHEN ccs.cc_call_center_sk IS NOT NULL THEN 'CALL_CENTER' ELSE 'OTHER' END AS location_type,
    CASE WHEN jm.has_null_sales = 1 THEN 'NULL_SALES_PRESENT' ELSE 'NO_NULLS' END AS null_sales_flag,
    (SELECT COUNT(*) FROM sales_aggr s2 WHERE s2.channel = jm.channel AND s2.total_sales > jm.total_sales) + 1 AS sales_rank_alternate
FROM joined_metrics jm
LEFT JOIN call_center_stats ccs ON jm.location_sk = ccs.cc_call_center_sk
WHERE
    (jm.year BETWEEN 1998 AND 2002 OR jm.year = 0)
    AND (jm.total_sales > 0 OR jm.total_refund IS NOT NULL)
    AND (jm.sales_rank <= 10 OR jm.total_profit > 10000)
    AND (COALESCE(jm.total_sales, 0) + COALESCE(jm.total_refund, 0) <> 0)
ORDER BY jm.channel, jm.sales_rank
LIMIT 50
