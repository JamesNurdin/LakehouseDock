WITH ss_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ss.ss_quantity) AS store_qty,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    WHERE ss.ss_net_paid > 0
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk
),
union_desc AS (
    SELECT DISTINCT r.r_reason_desc AS description
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_return_amt > 100
    UNION
    SELECT DISTINCT p.p_promo_name AS description
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
)
SELECT
    d_sales.d_year,
    d_sales.d_month_seq,
    cc.cc_name,
    ws.web_name,
    p.p_promo_name,
    COUNT(DISTINCT ss_agg.ss_store_sk) AS distinct_store_cnt,
    SUM(ss_agg.store_net_paid) AS total_net_paid,
    AVG(ss_agg.store_qty) AS avg_qty_per_store,
    MIN(ss_agg.store_net_paid) AS min_net_paid,
    MAX(ss_agg.store_net_paid) AS max_net_paid,
    ROW_NUMBER() OVER (PARTITION BY d_sales.d_year ORDER BY SUM(ss_agg.store_net_paid) DESC) AS rn_year,
    (SELECT COUNT(*) FROM union_desc) AS total_descriptions
FROM ss_agg
JOIN date_dim d_sales
    ON ss_agg.ss_sold_date_sk = d_sales.d_date_sk
JOIN store_sales ss
    ON ss.ss_store_sk = ss_agg.ss_store_sk
   AND ss.ss_sold_date_sk = ss_agg.ss_sold_date_sk
JOIN time_dim t_sales
    ON ss.ss_sold_time_sk = t_sales.t_time_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN catalog_sales cs
    ON cs.cs_order_number = ss.ss_ticket_number
   AND cs.cs_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t_catalog
    ON cs.cs_sold_time_sk = t_catalog.t_time_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cc_close
    ON cc.cc_closed_date_sk = d_cc_close.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_sales.d_date_sk
JOIN date_dim d_ws_close
    ON ws.web_close_date_sk = d_ws_close.d_date_sk
JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN time_dim t_return
    ON sr.sr_return_time_sk = t_return.t_time_sk
WHERE d_sales.d_year = 2001
  AND d_sales.d_month_seq BETWEEN 1200 AND 1211
  AND p.p_promo_name LIKE '%Summer%'
  AND cc.cc_name = 'Call Center 1'
  AND ws.web_name = 'WebSite 1'
GROUP BY d_sales.d_year, d_sales.d_month_seq, cc.cc_name, ws.web_name, p.p_promo_name
HAVING SUM(ss_agg.store_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
