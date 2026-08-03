WITH ss_agg AS (
    SELECT
        ss_store_sk,
        ss_sold_date_sk,
        ss_promo_sk,
        SUM(ss_net_profit)   AS store_profit,
        SUM(ss_quantity)     AS store_qty
    FROM tpcds.store_sales
    WHERE ss_sold_date_sk BETWEEN 2450815 AND 2451150  -- filter to a specific year range (e.g., 2022)
    GROUP BY ss_store_sk, ss_sold_date_sk, ss_promo_sk
)
SELECT
    s.s_store_name,
    s.s_state,
    d.d_year,
    cc.cc_company_name,
    p.p_promo_name,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Discounted' ELSE 'Regular' END AS promo_category,
    r.r_reason_desc,
    wp.wp_type,
    ws.web_name,
    cr.cr_return_amount,
    ss_agg.store_profit,
    ss_agg.store_qty,
    RANK() OVER (PARTITION BY d.d_year ORDER BY ss_agg.store_profit DESC) AS profit_rank
FROM ss_agg
JOIN tpcds.store s
  ON ss_agg.ss_store_sk = s.s_store_sk
JOIN tpcds.date_dim d
  ON ss_agg.ss_sold_date_sk = d.d_date_sk
JOIN tpcds.promotion p
  ON ss_agg.ss_promo_sk = p.p_promo_sk
JOIN tpcds.catalog_returns cr
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN tpcds.time_dim t
  ON cr.cr_returned_time_sk = t.t_time_sk
JOIN tpcds.call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN tpcds.customer c
  ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN tpcds.customer_address ca
  ON c.c_current_addr_sk = ca.ca_address_sk
JOIN tpcds.customer_demographics cd
  ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.web_page wp
  ON wp.wp_customer_sk = c.c_customer_sk
JOIN tpcds.web_site ws
  ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2022                                 -- filter 1: year
  AND s.s_state = 'CA'                                 -- filter 2: store state
  AND cc.cc_company_name = 'anti'                     -- filter 3: call‑center company name
  AND p.p_promo_name LIKE '%Holiday%'                 -- filter 4: promotion name pattern
  AND r.r_reason_desc IN ('Damaged', 'Defective')     -- filter 5: reason description
  AND wp.wp_type = 'home'                             -- filter 6: web page type
  AND t.t_hour BETWEEN 9 AND 17                       -- filter 7: business hours
  AND EXISTS (
        SELECT 1
        FROM tpcds.web_site ws2
        WHERE ws2.web_state = s.s_state
          AND ws2.web_tax_percentage < 0.08
    )
LIMIT 100
