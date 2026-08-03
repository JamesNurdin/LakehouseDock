/*
Goal: Identify stores (with managers whose names start with "J") that sold items whose description contains "soft",
combine sales with returns (full outer join to keep unmatched rows), enrich with promotion information via a cross‑join, apply string‑based filters and extractions, and rank stores by net profit.
*/
WITH filtered_stores AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        CONCAT(s.s_store_name, ' - ', s.s_city) AS store_full_name,
        s.s_market_manager
    FROM store s
    WHERE regexp_like(s.s_market_manager, '^J')
),
item_filtered AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        i.i_brand
    FROM item i
    WHERE i.i_item_desc LIKE '%soft%'
),
promo_subset AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        p.p_channel_radio
    FROM promotion p
    WHERE p.p_channel_radio = 'N'
),
cross_vals AS (
    SELECT 1 AS v UNION ALL SELECT 2
),
cross_joined AS (
    SELECT cv.v, ps.p_promo_sk
    FROM cross_vals cv
    CROSS JOIN promo_subset ps
)
SELECT
    fs.s_store_sk,
    fs.store_full_name,
    idf.i_brand,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_sales_tickets,
    SUM(ss.ss_net_paid) AS total_net_paid,
    COALESCE(SUM(sr.sr_return_amt_inc_tax), 0) AS total_return_amount,
    SUM(ss.ss_net_paid) - COALESCE(SUM(sr.sr_return_amt_inc_tax), 0) AS net_profit,
    ROW_NUMBER() OVER (ORDER BY (SUM(ss.ss_net_paid) - COALESCE(SUM(sr.sr_return_amt_inc_tax), 0)) DESC) AS rn,
    (
        SELECT regexp_extract(w.web_name, '(\\w+)', 1)
        FROM web_site w
        WHERE w.web_site_id = 'site_1'
        LIMIT 1
    ) AS extracted_web_name
FROM filtered_stores fs
JOIN store_sales ss ON ss.ss_store_sk = fs.s_store_sk
JOIN item_filtered idf ON ss.ss_item_sk = idf.i_item_sk
FULL OUTER JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
LEFT JOIN cross_joined cj ON cj.p_promo_sk = ss.ss_promo_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE cr.cr_item_sk = ss.ss_item_sk
      AND t.t_time_sk = ss.ss_sold_time_sk
)
GROUP BY
    fs.s_store_sk,
    fs.store_full_name,
    idf.i_brand
ORDER BY net_profit DESC, fs.s_store_sk
LIMIT 100
