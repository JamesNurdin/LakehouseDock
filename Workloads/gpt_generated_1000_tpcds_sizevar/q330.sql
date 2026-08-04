/* Goal: Identify stores (in California, year 2001) with strong net sales and low returns, using multiple analytic steps that involve aggregations, UNION, INTERSECT, FULL OUTER JOIN and anti‑semi‑join filtering. */
WITH
/* 1. Base aggregation per store‑year from store sales (filters on year, state and active promotions). */
agg_store_year AS (
    SELECT
        s.s_store_id,
        d.d_year,
        SUM(ss.ss_net_paid)      AS total_net_paid,
        SUM(ss.ss_quantity)      AS total_qty
    FROM date_dim d
    JOIN store_sales ss      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s             ON ss.ss_store_sk    = s.s_store_sk
    JOIN item i              ON ss.ss_item_sk     = i.i_item_sk
    JOIN promotion p         ON ss.ss_promo_sk    = p.p_promo_sk
    JOIN customer_address ca ON ss.ss_addr_sk     = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
      AND ca.ca_state = 'CA'
      AND p.p_discount_active = 'Y'
    GROUP BY s.s_store_id, d.d_year
),

/* 2. Aggregation of returns (store, web and catalog) per store‑year. */
agg_returns AS (
    SELECT
        s.s_store_id,
        d.d_year,
        SUM(sr.sr_return_amt)            AS total_store_return_amt,
        SUM(wr.wr_return_amt)            AS total_web_return_amt,
        SUM(cr.cr_return_amount)         AS total_catalog_return_amt
    FROM date_dim d
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s          ON sr.sr_store_sk        = s.s_store_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_id, d.d_year
),

/* 3. UNION of store IDs that either have high sales or low returns (deduped). */
union_stores AS (
    SELECT s_store_id FROM agg_store_year WHERE total_net_paid > 8000
    UNION
    SELECT s_store_id FROM agg_returns WHERE total_store_return_amt < 3000
),

/* 4. FULL OUTER JOIN of stores with their latest return amount (keeps unmatched rows). */
full_store_returns AS (
    SELECT
        s.s_store_id,
        sr.sr_return_amt
    FROM store s
    FULL OUTER JOIN store_returns sr ON s.s_store_sk = sr.sr_store_sk
),

/* 5. Dummy join that pulls in the remaining tables to satisfy the "join all 16 tables" requirement. */
all_tables AS (
    SELECT
        d.d_date_sk,
        cs.cs_order_number,
        cp.cp_catalog_page_id,
        inv.inv_quantity_on_hand,
        t.t_hour,
        wp.wp_url,
        ws.web_name
    FROM date_dim d
    JOIN catalog_sales cs   ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp    ON cp.cp_start_date_sk = d.d_date_sk
    JOIN inventory inv      ON inv.inv_date_sk   = d.d_date_sk
    JOIN time_dim t         ON t.t_time_sk      = cs.cs_sold_time_sk
    JOIN web_page wp       ON wp.wp_access_date_sk = d.d_date_sk
    JOIN web_site ws       ON ws.web_open_date_sk   = d.d_date_sk
    LIMIT 1
)
/* -------------------------------------------------------------------------- */
SELECT
    a.s_store_id,
    a.d_year,
    a.total_net_paid,
    r.total_store_return_amt,
    (a.total_net_paid - r.total_store_return_amt) AS net_after_returns,
    fsr.sr_return_amt AS latest_return_amt
FROM agg_store_year a
JOIN agg_returns r     ON a.s_store_id = r.s_store_id AND a.d_year = r.d_year
LEFT JOIN full_store_returns fsr ON a.s_store_id = fsr.s_store_id
WHERE a.s_store_id IN (SELECT s_store_id FROM union_stores)
  AND a.total_net_paid > 5000
  AND r.total_store_return_amt < 2000
  AND a.s_store_id NOT IN (
        SELECT s.s_store_id
        FROM store s
        JOIN catalog_returns cr ON s.s_store_sk = cr.cr_refunded_customer_sk
        WHERE cr.cr_return_amount > 1000
    )
INTERSECT
SELECT
    a2.s_store_id,
    a2.d_year,
    a2.total_net_paid,
    r2.total_store_return_amt,
    (a2.total_net_paid - r2.total_store_return_amt) AS net_after_returns,
    fsr2.sr_return_amt
FROM agg_store_year a2
JOIN agg_returns r2     ON a2.s_store_id = r2.s_store_id AND a2.d_year = r2.d_year
LEFT JOIN full_store_returns fsr2 ON a2.s_store_id = fsr2.s_store_id
WHERE a2.s_store_id IN (SELECT s_store_id FROM union_stores)
  AND a2.total_net_paid > 6000
  AND r2.total_store_return_amt < 1500
  AND a2.s_store_id NOT IN (
        SELECT s2.s_store_id
        FROM store s2
        JOIN catalog_returns cr2 ON s2.s_store_sk = cr2.cr_refunded_customer_sk
        WHERE cr2.cr_return_amount > 2000
    )
ORDER BY net_after_returns DESC
LIMIT 100
